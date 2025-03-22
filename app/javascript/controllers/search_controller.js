import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  selectAmazon(event) {
    const selectedItem = event.detail.item
    const name = selectedItem.textContent
    const asin = selectedItem.dataset.asin

    // 商品名をフォームに反映
    document.querySelector("input[name='amazon_item_name']").value = name

    // ASINをhiddenにセット
    document.querySelector("input[name='asin']").value = asin
  }
}
