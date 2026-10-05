import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import ChartManager from '@/components/ChartManager.vue'
import api from '@/services/api'

vi.mock('@/services/api', () => ({
  default: { getWorkingTimes: vi.fn() }
}))

// chart.js needs a canvas — stub the child components
const global = {
  stubs: {
    Bar: true,
    Pie: true,
    LineChart: true
  },
  mocks: {
    $route: { params: { userID: '1' } }
  }
}

function mountComponent() {
  return mount(ChartManager, { global })
}

describe('ChartManager.vue', () => {
  beforeEach(() => vi.clearAllMocks())

  it('fetches working times on mount', async () => {
    api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
    mountComponent()
    await vi.waitFor(() => expect(api.getWorkingTimes).toHaveBeenCalledWith('1'))
  })

  it('shows empty state when no data', async () => {
    api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
    const wrapper = mountComponent()
    await vi.waitFor(() => {
      expect(wrapper.text()).toContain('Aucune donnée')
    })
  })

  describe('hoursBetween', () => {
    it('computes hours between two ISO strings', () => {
      const wrapper = mountComponent()
      const hours = wrapper.vm.hoursBetween(
        '2026-09-22T09:00:00Z',
        '2026-09-22T17:00:00Z'
      )
      expect(hours).toBe(8)
    })
  })

  describe('computeHoursByDay', () => {
    it('sums hours per weekday, Monday first', () => {
      api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
      const wrapper = mountComponent()

      // 2026-09-21 is a Monday, 2026-09-22 a Tuesday
      wrapper.vm.workingtimes = [
        { start: '2026-09-21T09:00:00Z', end: '2026-09-21T12:00:00Z' }, // Mon 3h
        { start: '2026-09-21T13:00:00Z', end: '2026-09-21T17:00:00Z' }, // Mon 4h
        { start: '2026-09-22T09:00:00Z', end: '2026-09-22T17:00:00Z' }  // Tue 8h
      ]
      const totals = wrapper.vm.computeHoursByDay()

      expect(totals[0]).toBe(7) // Monday
      expect(totals[1]).toBe(8) // Tuesday
      expect(totals[2]).toBe(0) // Wednesday
    })

    it('ignores open sessions (no end)', () => {
      api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
      const wrapper = mountComponent()
      wrapper.vm.workingtimes = [
        { start: '2026-09-21T09:00:00Z', end: null }
      ]
      const totals = wrapper.vm.computeHoursByDay()
      expect(totals.every(v => v === 0)).toBe(true)
    })
  })

  describe('computeHoursByDate', () => {
    it('groups hours by real date', () => {
      api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
      const wrapper = mountComponent()
      wrapper.vm.workingtimes = [
        { start: '2026-09-21T09:00:00Z', end: '2026-09-21T17:00:00Z' },
        { start: '2026-09-22T09:00:00Z', end: '2026-09-22T11:00:00Z' }
      ]
      const { labels, values } = wrapper.vm.computeHoursByDate()
      expect(labels).toEqual(['2026-09-21', '2026-09-22'])
      expect(values).toEqual([8, 2])
    })
  })
})
