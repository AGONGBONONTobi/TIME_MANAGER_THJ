<script>
export default {
  name: 'WorkingTime',
  data() {
    return {
      workingTime: null
    }
  },
  mounted() {
    this.fetchWorkingTime()
  },
  methods: {
    fetchWorkingTime() {
      // Simulate fetching working time data from an API or service
      setTimeout(() => {
        this.workingTime = '9:00 AM - 5:00 PM'
      }, 1000)
    }
  }
}
</script>

<template></template>


<style scoped>

</style>
