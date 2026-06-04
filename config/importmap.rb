# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'noshi_preview', preload: true
# Vendored locally (see vendor/javascript/) so the JPEG download has no runtime
# dependency on an external CDN. To update: download the matching version's
# UMD build into vendor/javascript/html-to-image.min.js.
pin 'html-to-image', to: 'html-to-image.min.js', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
