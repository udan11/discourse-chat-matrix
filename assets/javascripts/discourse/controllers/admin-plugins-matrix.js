import Controller from "@ember/controller";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { later } from "@ember/runloop";
import { clipboardCopy } from "discourse/lib/utilities";

export default class AdminPluginsMatrix extends Controller {
  copied = false;

  @action
  regenerateTokens() {
    ajax("/admin/plugins/matrix/tokens", {
      type: "POST",
    }).then((model) => {
      this.setProperties({ model });
    });
  }

  @action
  copyToClipboard(content) {
    if (clipboardCopy(content)) {
      this.set("copied", true);
      later(() => this.set("copied", false), 3000);
    }
  }
}
