from __future__ import annotations

import argparse
import base64
import io
import os
import sys
import threading
import tkinter as tk
from dataclasses import dataclass
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

import google.genai as genai
import PIL.Image
from PIL import ImageTk

DEFAULT_API_KEY = os.environ.get("ANTIGRAVITY_API_KEY", "sk-antigravity-local-key")
DEFAULT_API_ENDPOINT = os.environ.get(
    "ANTIGRAVITY_API_ENDPOINT", "http://127.0.0.1:8045"
)
DEFAULT_MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3.1-flash-image")
DEFAULT_STYLE_PROMPT = """
Generate a single square pixel art illustration using the provided reference image or images as the main guide for composition, framing, lighting, colour palette, and rendering quality.

Use the reference images together to keep the overall structure and art direction cohesive unless the main prompt explicitly asks for a change.
- Keep the image production ready and visually consistent.
- Match the reference images' overall style and pixel density.
- Avoid legible text, UI elements, letters, and numbers unless the main prompt explicitly asks for them.
""".strip()
RESAMPLING = getattr(PIL.Image, "Resampling", PIL.Image)
PREVIEW_SIZE = (360, 360)
SMALL_PREVIEW_SIZE = (172, 172)

@dataclass
class GenerationConfig:
    reference_images: tuple[Path, ...]
    output_image: Path
    prompt: str
    style_prompt: str
    model: str
    api_key: str
    api_endpoint: str
    debug: bool = False

def repo_root() -> Path:
    return Path(__file__).resolve().parent

def default_reference_image() -> Path:
    candidates = [
        repo_root()
        / "1.Codebase"
        / "src"
        / "assets"
        / "rebirth_challenge"
        / "rebirth_day_1.png",
        repo_root() / "1.Codebase" / "src" / "assets" / "blank background.png",
    ]
    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return candidates[0]

def default_reference_images() -> tuple[Path, ...]:
    return (default_reference_image(),)

def default_output_image() -> Path:
    return (
        repo_root()
        / "1.Codebase"
        / "src"
        / "assets"
        / "generated"
        / "generated_image.png"
    )

def extract_generated_image(response: object, debug: bool = False) -> PIL.Image.Image:
    if debug:
        print(f"  [debug] response type={type(response).__name__}")
        candidates = getattr(response, "candidates", None)
        print(
            f"  [debug] candidates={candidates!r}"
            if candidates is None
            else f"  [debug] {len(candidates)} candidate(s)"
        )

    candidates = getattr(response, "candidates", None) or []
    for candidate in candidates:
        content = getattr(candidate, "content", None)
        parts = getattr(content, "parts", None) or []
        image = _extract_image_from_parts(parts, debug=debug)
        if image is not None:
            return image

    parts = getattr(response, "parts", None) or []
    image = _extract_image_from_parts(parts, debug=debug)
    if image is not None:
        return image

    raise RuntimeError("The model response did not contain an inline image payload.")

def _extract_image_from_parts(parts, debug: bool = False) -> PIL.Image.Image | None:
    for part in parts:
        inline_data = getattr(part, "inline_data", None)
        if inline_data is None:
            continue

        data = getattr(inline_data, "data", None)
        if not data:
            continue

        mime_type = getattr(inline_data, "mime_type", "<unknown>")
        if debug:
            data_repr = repr(data[:64]) if isinstance(data, (bytes, str)) else repr(data)
            print(
                f"  [debug] inline_data mime_type={mime_type!r} "
                f"data type={type(data).__name__} "
                f"len={len(data)} first64={data_repr}"
            )

        if isinstance(data, str):
            candidates = [base64.b64decode(data)]
        else:
            try:
                b64_decoded = base64.b64decode(data)
            except Exception:
                b64_decoded = None
            candidates = [data] if b64_decoded is None else [data, b64_decoded]

        for raw_bytes in candidates:
            try:
                with io.BytesIO(raw_bytes) as buffer:
                    image = PIL.Image.open(buffer)
                    image.load()
                    return image.copy()
            except Exception as exc:
                if debug:
                    print(f"  [debug] PIL failed on candidate: {exc}")

    return None

def build_full_prompt(style_prompt: str, prompt: str) -> str:
    style_prompt = style_prompt.strip()
    prompt = prompt.strip()
    if not prompt:
        raise ValueError("Prompt cannot be empty.")
    if not style_prompt:
        return prompt
    return f"{style_prompt}\n\nMain prompt:\n{prompt}"

def normalize_output_path(path: Path) -> Path:
    return path if path.suffix else path.with_suffix(".png")

def format_reference_image_paths(paths: tuple[Path, ...]) -> str:
    return os.pathsep.join(str(path) for path in paths)

def parse_reference_image_paths(raw_value: str) -> tuple[Path, ...]:
    paths = tuple(
        Path(chunk.strip())
        for chunk in raw_value.split(os.pathsep)
        if chunk.strip()
    )
    if not paths:
        raise ValueError("At least one reference image is required.")
    return paths

def generate_single_image(config: GenerationConfig) -> PIL.Image.Image:
    reference_images = tuple(
        reference_image.expanduser().resolve()
        for reference_image in config.reference_images
    )
    output_image = normalize_output_path(config.output_image.expanduser())
    for reference_image in reference_images:
        if not reference_image.is_file():
            raise FileNotFoundError(f"Reference image not found: {reference_image}")

    client = genai.Client(
        api_key=config.api_key,
        http_options={"base_url": config.api_endpoint},
    )
    full_prompt = build_full_prompt(config.style_prompt, config.prompt)

    contents: list[object] = [full_prompt]
    for reference_image in reference_images:
        with PIL.Image.open(reference_image) as image:
            contents.append(image.copy())

    response = client.models.generate_content(
        model=config.model,
        contents=contents,
    )
    result = extract_generated_image(response, debug=config.debug)
    output_image.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_image, format="PNG")
    return result

class AssetImageGeneratorUI:
    def __init__(self, root: tk.Tk, args: argparse.Namespace) -> None:
        self.root = root
        self.args = args
        self.is_generating = False
        self._source_preview_img = None
        self._style_preview_img = None
        self._output_preview_img = None

        self.source_path_var = tk.StringVar(
            value=str(args.source_image) if args.source_image else ""
        )
        self.style_path_var = tk.StringVar(
            value=str(args.style_image) if args.style_image else ""
        )
        self.output_path_var = tk.StringVar(value=str(args.output))
        self.model_var = tk.StringVar(value=args.model)
        self.endpoint_var = tk.StringVar(value=args.api_endpoint)
        self.debug_var = tk.BooleanVar(value=args.debug)
        self.status_var = tk.StringVar(value="Ready.")

        self.root.title("Asset Image Generator")
        self.root.minsize(1100, 720)
        self._build_layout()
        self._set_text(self.style_prompt_text, args.style_prompt)
        self._set_text(
            self.prompt_text,
            args.prompt or "Describe the image you want to generate here.",
        )
        self._refresh_all_previews()

    def _build_layout(self) -> None:
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)

        main = ttk.Frame(self.root, padding=12)
        main.grid(row=0, column=0, sticky="nsew")
        main.columnconfigure(0, weight=3)
        main.columnconfigure(1, weight=2)
        main.rowconfigure(1, weight=1)

        
        controls = ttk.LabelFrame(main, text="Images & Settings", padding=8)
        controls.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 10))
        controls.columnconfigure(1, weight=1)

        self._path_row(
            controls, row=0, label="Image to Convert",
            var=self.source_path_var, browse=self._browse_source_image,
            on_change=lambda _: self._refresh_source_preview(),
        )
        self._path_row(
            controls, row=1, label="Style Reference",
            var=self.style_path_var, browse=self._browse_style_image,
            on_change=lambda _: self._refresh_style_preview(),
        )
        self._path_row(
            controls, row=2, label="Output Image",
            var=self.output_path_var, browse=self._browse_output_image,
            on_change=lambda _: self._refresh_output_preview(),
        )

        settings = ttk.Frame(controls)
        settings.grid(row=3, column=0, columnspan=3, sticky="ew", pady=(8, 0))
        settings.columnconfigure(1, weight=1)
        settings.columnconfigure(3, weight=2)
        ttk.Label(settings, text="Model").grid(row=0, column=0, sticky="w", padx=(0, 4))
        ttk.Entry(settings, textvariable=self.model_var, width=26).grid(
            row=0, column=1, sticky="ew", padx=(0, 16))
        ttk.Label(settings, text="API Endpoint").grid(row=0, column=2, sticky="w", padx=(0, 4))
        ttk.Entry(settings, textvariable=self.endpoint_var).grid(
            row=0, column=3, sticky="ew")

        
        editor = ttk.Frame(main)
        editor.grid(row=1, column=0, sticky="nsew", padx=(0, 10))
        editor.columnconfigure(0, weight=1)
        editor.rowconfigure(1, weight=1)
        editor.rowconfigure(3, weight=2)

        ttk.Label(editor, text="Style / Constraint Prompt").grid(row=0, column=0, sticky="w")
        self.style_prompt_text = tk.Text(editor, height=7, wrap="word")
        self.style_prompt_text.grid(row=1, column=0, sticky="nsew", pady=(4, 10))

        ttk.Label(editor, text="Main Prompt").grid(row=2, column=0, sticky="w")
        self.prompt_text = tk.Text(editor, height=10, wrap="word")
        self.prompt_text.grid(row=3, column=0, sticky="nsew", pady=(4, 0))

        actions = ttk.Frame(editor)
        actions.grid(row=4, column=0, sticky="ew", pady=(10, 0))
        actions.columnconfigure(2, weight=1)
        ttk.Checkbutton(actions, text="Debug", variable=self.debug_var).grid(
            row=0, column=0, sticky="w")
        ttk.Button(actions, text="Reload Previews",
                   command=self._refresh_all_previews).grid(
            row=0, column=1, sticky="w", padx=(8, 0))
        self.progress = ttk.Progressbar(actions, mode="indeterminate", length=100)
        self.progress.grid(row=0, column=2, sticky="ew", padx=(8, 8))
        self.generate_button = ttk.Button(
            actions, text="Generate Image", command=self._on_generate_clicked)
        self.generate_button.grid(row=0, column=3, sticky="e")

        
        previews = ttk.Frame(main)
        previews.grid(row=1, column=1, sticky="nsew")
        previews.columnconfigure(0, weight=1)
        previews.columnconfigure(1, weight=1)
        previews.rowconfigure(0, weight=1)
        previews.rowconfigure(1, weight=2)

        src_grp = ttk.LabelFrame(previews, text="Image to Convert")
        src_grp.grid(row=0, column=0, sticky="nsew", padx=(0, 4), pady=(0, 6))
        src_grp.columnconfigure(0, weight=1)
        src_grp.rowconfigure(0, weight=1)
        self.source_preview_label = ttk.Label(
            src_grp, text="No image selected.", anchor="center")
        self.source_preview_label.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        sty_grp = ttk.LabelFrame(previews, text="Style Reference")
        sty_grp.grid(row=0, column=1, sticky="nsew", padx=(4, 0), pady=(0, 6))
        sty_grp.columnconfigure(0, weight=1)
        sty_grp.rowconfigure(0, weight=1)
        self.style_preview_label = ttk.Label(
            sty_grp, text="No reference selected.", anchor="center")
        self.style_preview_label.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        out_grp = ttk.LabelFrame(previews, text="Generated Output")
        out_grp.grid(row=1, column=0, columnspan=2, sticky="nsew")
        out_grp.columnconfigure(0, weight=1)
        out_grp.rowconfigure(0, weight=1)
        self.output_preview_label = ttk.Label(
            out_grp, text="No generated image yet.", anchor="center")
        self.output_preview_label.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)

        
        ttk.Label(main, textvariable=self.status_var, anchor="w",
                  relief="sunken", padding=(4, 2)).grid(
            row=2, column=0, columnspan=2, sticky="ew", pady=(8, 0))

    def _path_row(
        self,
        parent: ttk.Frame,
        row: int,
        label: str,
        var: tk.StringVar,
        browse,
        on_change=None,
    ) -> None:
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 8), pady=2)
        entry = ttk.Entry(parent, textvariable=var)
        entry.grid(row=row, column=1, sticky="ew", padx=(0, 8), pady=2)
        if on_change:
            entry.bind("<Return>", on_change)
            entry.bind("<FocusOut>", on_change)
        ttk.Button(parent, text="Browse…", command=browse).grid(row=row, column=2, pady=2)

    

    def _browse_source_image(self) -> None:
        current = Path(self.source_path_var.get()).expanduser()
        selected = filedialog.askopenfilename(
            title="Choose image to convert",
            filetypes=[("Image Files", "*.png *.jpg *.jpeg *.webp *.bmp"), ("All Files", "*.*")],
            initialdir=str(current.parent if current.parent.exists() else repo_root()),
        )
        if selected:
            self.source_path_var.set(selected)
            self._refresh_source_preview()

    def _browse_style_image(self) -> None:
        current = Path(self.style_path_var.get()).expanduser()
        selected = filedialog.askopenfilename(
            title="Choose style reference image",
            filetypes=[("Image Files", "*.png *.jpg *.jpeg *.webp *.bmp"), ("All Files", "*.*")],
            initialdir=str(current.parent if current.parent.exists() else repo_root()),
        )
        if selected:
            self.style_path_var.set(selected)
            self._refresh_style_preview()

    def _browse_output_image(self) -> None:
        current = Path(self.output_path_var.get()).expanduser()
        selected = filedialog.asksaveasfilename(
            title="Choose where to save the generated image",
            defaultextension=".png",
            filetypes=[("PNG Image", "*.png"), ("All Files", "*.*")],
            initialdir=str(current.parent if current.parent.exists() else repo_root()),
            initialfile=current.name or "generated_image.png",
        )
        if selected:
            self.output_path_var.set(selected)
            self._refresh_output_preview()

    

    def _refresh_all_previews(self) -> None:
        self._refresh_source_preview()
        self._refresh_style_preview()
        self._refresh_output_preview()

    def _refresh_source_preview(self) -> None:
        self._load_preview(
            Path(self.source_path_var.get().strip()),
            self.source_preview_label, "No image selected.",
            "_source_preview_img", SMALL_PREVIEW_SIZE,
        )

    def _refresh_style_preview(self) -> None:
        self._load_preview(
            Path(self.style_path_var.get().strip()),
            self.style_preview_label, "No reference selected.",
            "_style_preview_img", SMALL_PREVIEW_SIZE,
        )

    def _refresh_output_preview(self) -> None:
        self._load_preview(
            Path(self.output_path_var.get().strip()),
            self.output_preview_label, "No generated image yet.",
            "_output_preview_img", PREVIEW_SIZE,
        )

    def _load_preview(
        self,
        path: Path,
        label: ttk.Label,
        missing_text: str,
        attr: str,
        size: tuple[int, int],
    ) -> None:
        try:
            if not path.is_file():
                label.configure(text=missing_text, image="")
                setattr(self, attr, None)
                return
            with PIL.Image.open(path) as img:
                preview = img.copy()
            preview.thumbnail(size, RESAMPLING.LANCZOS)
            tk_img = ImageTk.PhotoImage(preview)
            label.configure(image=tk_img, text="")
            setattr(self, attr, tk_img)
        except Exception as exc:
            label.configure(text=f"Preview failed: {exc}", image="")
            setattr(self, attr, None)

    

    def _set_text(self, widget: tk.Text, value: str) -> None:
        widget.delete("1.0", tk.END)
        widget.insert("1.0", value)

    def _get_text(self, widget: tk.Text) -> str:
        return widget.get("1.0", tk.END).strip()

    

    def _collect_config(self) -> GenerationConfig:
        source_path = Path(self.source_path_var.get().strip())
        style_path = Path(self.style_path_var.get().strip())
        output_image = normalize_output_path(Path(self.output_path_var.get().strip()))
        prompt = self._get_text(self.prompt_text)
        style_prompt = self._get_text(self.style_prompt_text)

        if not source_path.name:
            raise ValueError("Please select an image to convert.")
        if not style_path.name:
            raise ValueError("Please select a style reference image.")
        if not prompt:
            raise ValueError("Main prompt cannot be empty.")

        self.output_path_var.set(str(output_image))
        
        return GenerationConfig(
            reference_images=(style_path, source_path),
            output_image=output_image,
            prompt=prompt,
            style_prompt=style_prompt,
            model=self.model_var.get().strip() or DEFAULT_MODEL,
            api_key=self.args.api_key,
            api_endpoint=self.endpoint_var.get().strip() or DEFAULT_API_ENDPOINT,
            debug=self.debug_var.get(),
        )

    

    def _on_generate_clicked(self) -> None:
        if self.is_generating:
            return
        try:
            config = self._collect_config()
        except Exception as exc:
            messagebox.showerror("Invalid Input", str(exc), parent=self.root)
            return
        self.is_generating = True
        self.generate_button.state(["disabled"])
        self.progress.start(10)
        self.status_var.set("Generating image…")
        threading.Thread(
            target=self._generate_in_background, args=(config,), daemon=True
        ).start()

    def _generate_in_background(self, config: GenerationConfig) -> None:
        try:
            image = generate_single_image(config)
            self.root.after(0, self._on_generation_success, image, config.output_image)
        except Exception as exc:
            self.root.after(0, self._on_generation_error, str(exc))

    def _on_generation_success(self, image: PIL.Image.Image, output_image: Path) -> None:
        self.is_generating = False
        self.generate_button.state(["!disabled"])
        self.progress.stop()
        self.status_var.set(f"Saved to {output_image}")
        self.output_path_var.set(str(output_image))
        self._show_generated_preview(image)

    def _on_generation_error(self, message: str) -> None:
        self.is_generating = False
        self.generate_button.state(["!disabled"])
        self.progress.stop()
        self.status_var.set("Generation failed.")
        messagebox.showerror("Generation Failed", message, parent=self.root)

    def _show_generated_preview(self, image: PIL.Image.Image) -> None:
        preview = image.copy()
        preview.thumbnail(PREVIEW_SIZE, RESAMPLING.LANCZOS)
        tk_img = ImageTk.PhotoImage(preview)
        self.output_preview_label.configure(image=tk_img, text="")
        self._output_preview_img = tk_img

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate one image guided by one or more reference images."
    )
    parser.add_argument(
        "--reference-image",
        type=Path,
        action="append",
        dest="reference_images",
        help="Repeat this flag to provide multiple reference images (used by --no-ui).",
    )
    parser.add_argument(
        "--source-image",
        type=Path,
        dest="source_image",
        default=None,
        help="Image to convert (pre-fills the 'Image to Convert' UI field).",
    )
    parser.add_argument(
        "--style-image",
        type=Path,
        dest="style_image",
        default=None,
        help="Style reference image (pre-fills the 'Style Reference' UI field).",
    )
    parser.add_argument("--output", type=Path, default=default_output_image())
    parser.add_argument("--prompt", default="")
    parser.add_argument("--style-prompt", default=DEFAULT_STYLE_PROMPT)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--api-key", default=DEFAULT_API_KEY)
    parser.add_argument("--api-endpoint", default=DEFAULT_API_ENDPOINT)
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Print raw response structure and inline_data details.",
    )
    parser.add_argument(
        "--no-ui",
        action="store_true",
        help="Run a single generation from the command line instead of opening the UI.",
    )
    args = parser.parse_args()
    if not args.reference_images:
        args.reference_images = list(default_reference_images())
    else:
        args.reference_images = [path.expanduser() for path in args.reference_images]
    
    if args.style_image is None and args.reference_images:
        args.style_image = args.reference_images[0]
    if args.source_image is None and len(args.reference_images) > 1:
        args.source_image = args.reference_images[1]
    return args

def run_cli(args: argparse.Namespace) -> int:
    config = GenerationConfig(
        reference_images=tuple(args.reference_images),
        output_image=args.output,
        prompt=args.prompt,
        style_prompt=args.style_prompt,
        model=args.model,
        api_key=args.api_key,
        api_endpoint=args.api_endpoint,
        debug=args.debug,
    )
    try:
        generate_single_image(config)
    except Exception as exc:
        print(f"Generation failed: {exc}", file=sys.stderr)
        return 1

    print(f"Saved generated image to {normalize_output_path(args.output)}")
    return 0

def run_ui(args: argparse.Namespace) -> int:
    root = tk.Tk()
    AssetImageGeneratorUI(root, args)
    root.mainloop()
    return 0

def main() -> int:
    args = parse_args()
    if args.no_ui:
        if not args.prompt.strip():
            print("--prompt is required when using --no-ui.", file=sys.stderr)
            return 1
        return run_cli(args)
    return run_ui(args)

if __name__ == "__main__":
    raise SystemExit(main())
