# README

You can see the app here: https://noshi.onrender.com/

- Ruby 3.2.2, Rails 7.0.3, Hotwire/ImportMaps

- System dependencies: Tailwind

- Unused, removed, dependences: PG, Devise, ActiveStorage:GCS

- Tests with MiniTest (no tests currently implemented)

- ActiveJob for MiniMagick noshi generation code works, but functionality is currently commented out.

- Uses an internal JS class to track changes and encode them in a form, then uses hotwire to trigger image generation with htmlToImage, and append.

Should work out of the box on Render
