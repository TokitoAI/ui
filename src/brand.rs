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

/// Paint the bare Tokito brand mark at the given side length (height in
/// points; width is derived from the mark's native aspect ratio).
///
/// Use this when the mark sits directly on the page (e.g. inside a marketing
/// card). For chrome — sidebars, headers, dock rails — prefer
/// [`brand_tile`], which wraps the mark in the brand's "App icon" lockup.
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

/// Brand "App icon" tile — a dark rounded square with the mark inset.
///
/// Matches the App-icon card in the Tokito logo sheet (`#07101E` navy
/// tile, ~24 % corner radius, mark filling ~70 % of the tile's width).
/// This is the lockup to use anywhere the mark sits in chrome (header
/// brand block, sidebar rail, dock icon) — it gives the mark a
/// container the eye can rest on instead of floating it on the page.
pub fn brand_tile(ui: &mut Ui, side: f32) -> Response {
    let (rect, response) = ui.allocate_exact_size(egui::vec2(side, side), Sense::hover());
    let painter = ui.painter();
    let tile_fill = Color32::from_rgb(0x07, 0x10, 0x1e);
    let radius = side * 0.235; // matches the Figma's 36 / 150 corner ratio.
    painter.rect_filled(rect, egui::Rounding::same(radius), tile_fill);

    // Inset the mark to ~70 % of the tile, centred. The mark's native
    // aspect is slightly taller than square, so derive the rect from
    // a uniform height target and centre horizontally.
    let mark_h = side * 0.7;
    let mark_w = mark_h * MARK_ASPECT;
    let mark_rect = egui::Rect::from_center_size(rect.center(), egui::vec2(mark_w, mark_h));
    let handle = texture(ui.ctx());
    painter.image(
        handle.id(),
        mark_rect,
        egui::Rect::from_min_max(egui::pos2(0.0, 0.0), egui::pos2(1.0, 1.0)),
        Color32::WHITE,
    );
    response
}
