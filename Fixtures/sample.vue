<template>
  <button @click="count++">Clicked {{ count }} times</button>
</template>

<script setup>
import { ref } from 'vue'
const count = ref(0)
</script>

<style scoped>
button { font-weight: bold; }
</style>
