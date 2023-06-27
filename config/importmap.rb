# Pin npm packages by running ./bin/importmap

pin 'application', preload: true
pin 'noshi_preview', preload: true
pin 'html-to-image', to: 'https://cdnjs.cloudflare.com/ajax/libs/html-to-image/1.11.11/html-to-image.min.js',
                     preload: true
pin 'downloadjs', to: 'https://cdnjs.cloudflare.com/ajax/libs/downloadjs/1.4.8/download.min.js', preload: true
pin '@hotwired/turbo-rails', to: 'turbo.min.js', preload: true
pin '@hotwired/stimulus', to: 'stimulus.min.js', preload: true
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js', preload: true
pin_all_from 'app/javascript/controllers', under: 'controllers'
