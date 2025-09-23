// .vitepress/theme/index.ts
import DefaultTheme from 'vitepress/theme'
import './custom.css';

// 组件
import HomeSponsors from './components/HomeSponsors.vue'
import { h } from 'vue' // h函数

import { Swiper, SwiperSlide } from 'swiper/vue';
import { Navigation, Pagination, Autoplay } from 'swiper/modules';
import 'swiper/css';
import 'swiper/css/navigation';
import 'swiper/css/pagination';
import { withBase } from 'vitepress';

export default {
  extends: DefaultTheme,
  markdown: {
    image: {
      // 默认禁用；设置为 true 可为所有图片启用懒加载。
      lazyLoading: true
    }
  },
  enhanceApp({ app }) {
    // 注册 Swiper 组件
    app.component('Swiper', Swiper);
    app.component('SwiperSlide', SwiperSlide);
  },
  Layout() {
    return h(DefaultTheme.Layout, null, {

      // 指定组件使用home-features-after插槽
      // 'home-features-after': () => h(HomeSponsors),

    })
  }

}