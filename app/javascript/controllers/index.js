// This file is auto-generated by ./bin/rails stimulus:manifest:update
// Run that command whenever you add a new controller or create them with
// ./bin/rails generate stimulus controllerName

import { application } from "./application"

// import AutocompleteController from "./autocomplete_controller"
// application.register("autocomplete", AutocompleteController)

import Autocomplete from "stimulus-autocomplete"
application.register("autocomplete", Autocomplete)

// import CommentController from "./comment_controller";
// application.register("comment", CommentController);

import HelloController from "./hello_controller"
application.register("hello", HelloController)

import ReleasableItemsController from "./releasable_items_controller"
application.register("releasable-items", ReleasableItemsController)

import ImagePreviewController from "./image_preview_controller";
application.register("image-preview", ImagePreviewController);

// ユーザー側で一括既読するように変更のためコメントアウト
// import NotificationsController from "./notifications_controller";
// application.register("notifications", NotificationsController);

import SearchToggleController from "./search_toggle_controller"
application.register("search-toggle", SearchToggleController)