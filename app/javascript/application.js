// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"
import { Application } from "@hotwired/stimulus"
import { Autocomplete } from "stimulus-autocomplete"

const application = Application.start()
application.register("autocomplete", Autocomplete)

// Configure Stimulus development experience
// application.debug = false
// window.Stimulus = application
// 
// export { application }