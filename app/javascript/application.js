// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// SwiperをTurboに対応させて初期化
document.addEventListener('turbo:load', () => {
  const containers = document.querySelectorAll('.swiper-container')

  containers.forEach((container) => {
    const swiperEl = container.querySelector('.swiper')

    new Swiper(swiperEl, {
      loop: false,
      slidesPerView: 1,
      spaceBetween: 16,
      pagination: {
        el: container.querySelector('.swiper-pagination'),
        clickable: true,
      }
    })
  })
})
