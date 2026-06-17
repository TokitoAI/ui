//! The Tokito brand mark.
//!
//! Ships as a pre-rendered PNG (`assets/tokito-mark.png`) instead of an SVG
//! so the runtime stays free of `resvg`/`tiny-skia`. Decoded once per
//! [`egui::Context`] via `ctx.data_mut`, cached as an [`egui::TextureHandle`].

use egui::{Color32, ColorImage, Context, Id, Response, Sense, TextureHandle, TextureOptions, Ui};

const MARK_PNG: &[u8] = include_bytes!("assets/tokito-mark.png");
const MARK_ASPECT: f32 = 178.0 / 190.0; // viewBox width / height

#[derive(Clone)]
struct CachedMark(TextureHandle);

fn texture(ctx: &Context) -> TextureHandle {
    let id = Id::new("tokito_ui::brand_mark");
    if let Some(cached) = ctx.data(|d| d.get_temp::<CachedMark>(id).map(|c| c.0)) {
        return cached;
    }
    let image = image::load_from_memory(MARK_PNG)
        .expect("tokito_ui: tokito-mark.png is invalid PNG")
        .to_rgba8();
    let size = [image.width() as usize, image.height() as usize];
    let color = ColorImage::from_rgba_unmultiplied(size, image.as_raw());
    let handle = ctx.load_texture("tokito_mark", color, TextureOptions::LINEAR);
    ctx.data_mut(|d| d.insert_temp(id, CachedMark(handle.clone())));
    handle
}

/// Paint the Tokito brand mark at the given side length (height in points;
/// width is derived from the mark's native aspect ratio).
///
/// Allocates a non-interactive rect. The returned [`Response`] can be used
/// to mount tooltips or to detect hover for an alternate effect at the call
/// site.
pub fn brand_mark(ui: &mut Ui, side: f32) -> Response {
    let handle = texture(ui.ctx());
    let w = side * MARK_ASPECT;
    let (rect, response) = ui.allocate_exact_size(egui::vec2(w, side), Sense::hover());
    ui.painter().image(
        handle.id(),
        rect,
        egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0)),
        Color32::WHITE,
    );
    response
}
