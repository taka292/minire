// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// app/javascript/application.js
// import Swiper from 'swiper/bundle'
// import 'swiper/css/bundle'

// SwiperをTurboに対応させて初期化
document.addEventListener('turbo:load', () => {
  const carousels = document.querySelectorAll('.swiper')

  carousels.forEach((carousel) => {
    new Swiper(carousel, {
      loop: false,
      slidesPerView: 1,
      spaceBetween: 16,
      pagination: {
        el: carousel.querySelector('.swiper-pagination'),
        clickable: true,
      }
    })
  })
})
