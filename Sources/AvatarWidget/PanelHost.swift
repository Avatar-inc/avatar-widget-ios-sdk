/// Panel host baked into this SDK artifact (proposal: customers never pass a URL).
///
/// - Default / UAT artifact → `widget-uat.myegdev2.com` (matches `src-panel/.env.uat`)
/// - Production release: build with `AVATAR_WIDGET_PRODUCTION` (CI / prod SPM tag)
enum PanelHost {
    static var origin: String {
        #if AVATAR_WIDGET_PRODUCTION
        "https://widget.avatar.inc"
        #else
        "https://widget-uat.myegdev2.com"
        #endif
    }
}
