---
# https://vitepress.dev/reference/default-theme-home-page
layout: home




---

<div class="beauty-img-grid">
  <img
    v-for="(src, idx) in imageUrls"
    :key="idx"
    :src="withBase(src)"
    :alt="src.split('/').pop() || ''"
    @click="openSwiper"
  />
</div>

<!-- 轮播模态框 -->
<div v-if="showSwiper" class="swiper-modal" @click="closeSwiper">
  <div class="swiper-modal-content" @click.stop>
    <button class="swiper-close" @click="closeSwiper">×</button>
    <div class="swiper-counter">{{ currentSlideIndex + 1 }} / {{ images.length }}</div>
    <div class="beauty-swiper">
      <Swiper
        :modules="[Navigation, Pagination, Autoplay]"
        :slides-per-view="1"
        :space-between="0"
        :navigation="true"
        :pagination="{ clickable: true }"
        :initial-slide="currentImageIndex"
        :loop="true"
        :keyboard="{ enabled: true }"
        @swiper="onSwiperInit"
        @slideChange="onSlideChange"
        class="swiper-container"
      >
        <SwiperSlide v-for="(image, index) in images" :key="index">
          <img :src="image.src" :alt="image.alt" class="swiper-image" />
        </SwiperSlide>
      </Swiper>
    </div>
  </div>
</div>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { withBase } from 'vitepress'
import imageUrls from 'virtual:images'
import { Navigation, Pagination, Autoplay } from 'swiper/modules'

const showSwiper = ref(false)
const currentImageIndex = ref(0)
const currentSlideIndex = ref(0)
const images = ref([])
let swiperInstance = null

// 从虚拟模块获取图片列表
const getImagesFromDOM = () => {
  const list = imageUrls.map((url) => ({
    src: withBase(url),
    alt: url.split('/').pop() || ''
  }))
  images.value = list
}

const openSwiper = (event) => {
  // 获取被点击的图片索引
  const clickedImg = event.target
  const imgElements = document.querySelectorAll('.beauty-img-grid img')
  const index = Array.from(imgElements).indexOf(clickedImg)
  
  currentImageIndex.value = index
  currentSlideIndex.value = index
  showSwiper.value = true
  // 防止背景滚动
  document.body.style.overflow = 'hidden'
}

const closeSwiper = () => {
  showSwiper.value = false
  swiperInstance = null
  // 恢复背景滚动
  document.body.style.overflow = 'auto'
}

// 键盘事件处理
const handleKeydown = (event) => {
  if (!showSwiper.value) return
  
  switch (event.key) {
    case 'Escape':
      closeSwiper()
      break
    case 'ArrowLeft':
      if (swiperInstance) {
        swiperInstance.slidePrev()
      }
      break
    case 'ArrowRight':
      if (swiperInstance) {
        swiperInstance.slideNext()
      }
      break
    case 'ArrowUp':
      event.preventDefault()
      if (swiperInstance) {
        swiperInstance.slidePrev()
      }
      break
    case 'ArrowDown':
      event.preventDefault()
      if (swiperInstance) {
        swiperInstance.slideNext()
      }
      break
  }
}

// Swiper实例初始化
const onSwiperInit = (swiper) => {
  swiperInstance = swiper
}

// 幻灯片变化事件
const onSlideChange = (swiper) => {
  currentSlideIndex.value = swiper.realIndex
}

// 组件生命周期
onMounted(() => {
  // 页面渲染完成后获取图片信息
  getImagesFromDOM()
  document.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown)
})
</script>