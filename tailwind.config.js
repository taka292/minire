module.exports = {
  mode: 'jit',
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
    theme: {
    extend: {
        colors: {
        customBlue: '#3BB1D8', // カスタムカラー名を定義
        },
        keyframes: {
        fadeInUp: {
          '0%': { opacity: 0, transform: 'translateY(20px)' },
          '100%': { opacity: 1, transform: 'translateY(0)' },
        },
        },
        animation: {
          fadeInUp: 'fadeInUp 0.6s ease-out forwards',
        },
    },
  },
  plugins: [require("daisyui")],
  daisyui: {
    // base: false,
    darkTheme: false,
  },
}