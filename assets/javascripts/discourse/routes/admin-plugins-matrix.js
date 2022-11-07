import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class AdminPluginsChatRoute extends DiscourseRoute {
  model() {
    return ajax("/admin/plugins/matrix");
  }
}
