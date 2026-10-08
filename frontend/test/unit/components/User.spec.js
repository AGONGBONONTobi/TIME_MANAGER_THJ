import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import User from '@/components/User.vue'
import api from '@/services/api'
import { readAuthUser } from '@/utils/auth'

vi.mock('@/services/api', () => ({
  default: {
    getUser: vi.fn(),
    createUser: vi.fn(),
    updateUser: vi.fn(),
    deleteUser: vi.fn(),
    getWorkingTimes: vi.fn(),
    getUserWorkPolicy: vi.fn(),
    clockInOut: vi.fn()
  }
}))

vi.mock('@/utils/auth', () => ({
  readAuthUser: vi.fn(() => ({ id: 1, username: 'Joseph' }))
}))

const POLICY = {
  weekly_hours: 35,
  work_days: 5,
  night_start: '21:00:00',
  night_end: '06:00:00'
}

function mountComponent() {
  return mount(User, {
    global: { stubs: { 'router-link': true } }
  })
}

describe('User.vue', () => {
  let intervalSpy

  beforeEach(() => {
    vi.clearAllMocks()
    intervalSpy = vi.spyOn(window, 'setInterval').mockReturnValue(1)
    vi.spyOn(window, 'clearInterval').mockImplementation(() => {})
    // Default: user 1, logged in, no working times, no policy
    readAuthUser.mockReturnValue({ id: 1, username: 'Joseph' })
    api.getUser.mockResolvedValue({ data: { data: { id: 1, username: 'Joseph' } } })
    api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })
    api.getUserWorkPolicy.mockResolvedValue({ data: { data: null } })
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  // ─── Initial load ─────────────────────────────────────────────
  describe('initial load', () => {
    it('reads userId from the authenticated user', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.userId).toBe(1)
    })

    it('fetches working times for that user', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getWorkingTimes).toHaveBeenCalledWith(1)
    })

    it('fetches the user profile', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getUser).toHaveBeenCalledWith(1)
    })

    it('fetches the work policy', async () => {
      mountComponent()
      await flushPromises()
      expect(api.getUserWorkPolicy).toHaveBeenCalledWith(1)
    })

    it('clears loading after fetch', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.isLoading).toBe(false)
    })

    it('stores the fetched working times', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.workingTimes).toHaveLength(1)
    })

    it('shows an error when the working times fetch fails', async () => {
      api.getWorkingTimes.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.errorMessage).toContain('Impossible de charger')
    })

    it('sets up a 1-second interval', () => {
      mountComponent()
      expect(intervalSpy).toHaveBeenCalledWith(expect.any(Function), 1000)
    })

    it('renders the displayName from auth user', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.text()).toContain('Bonjour, Joseph')
    })

    it('does nothing when there is no authenticated user', async () => {
      readAuthUser.mockReturnValue(null)
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.userId).toBeNull()
      expect(api.getWorkingTimes).not.toHaveBeenCalled()
      expect(wrapper.vm.isLoading).toBe(false)
      expect(wrapper.text()).toContain('Bonjour, Utilisateur')
    })
  })

  // ─── Active session ───────────────────────────────────────────
  describe('active session detection', () => {
    it('activeSession is null when there are no sessions', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.activeSession).toBeNull()
      expect(wrapper.vm.isClockedIn).toBe(false)
    })

    it('finds the session with no end', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: {
          data: [
            { id: 1, start: '2026-09-22T09:00:00Z', end: '2026-09-22T12:00:00Z' },
            { id: 2, start: '2026-09-22T13:00:00Z', end: null }
          ]
        }
      })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.activeSession.id).toBe(2)
      expect(wrapper.vm.isClockedIn).toBe(true)
    })
  })

  // ─── Elapsed timer ────────────────────────────────────────────
  describe('elapsed time', () => {
    it('is zero when not clocked in', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.elapsedSeconds).toBe(0)
    })

    it('counts seconds since the session started', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.now = new Date('2026-09-22T10:30:00Z')
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.elapsedSeconds).toBe(5400)
    })

    it('formats elapsed as HH:MM:SS', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: { data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: null }] }
      })
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.now = new Date('2026-09-22T09:01:05Z')
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.elapsedLabel).toBe('00:01:05')
    })
  })

  // ─── Duration math ────────────────────────────────────────────
  describe('durationInMinutes', () => {
    it('computes minutes between start and end', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.durationInMinutes({
        start: '2026-09-22T09:00:00Z',
        end: '2026-09-22T10:30:00Z'
      })).toBe(90)
    })

    it('uses "now" for an open session', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.now = new Date('2026-09-22T10:00:00Z')
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.durationInMinutes({
        start: '2026-09-22T09:00:00Z',
        end: null
      })).toBe(60)
    })
  })

  // ─── Night hours ──────────────────────────────────────────────
  describe('nightMinutesForSession', () => {
    it('returns 0 for a pure daytime session', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      const minutes = wrapper.vm.nightMinutesForSession({
        start: '2026-09-22T09:00:00',
        end: '2026-09-22T17:00:00'
      })
      expect(minutes).toBe(0)
    })

    it('counts minutes between 21:00 and 06:00 local time', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      const start = new Date('2026-09-22T22:00:00')
      const end = new Date('2026-09-23T02:00:00')
      const minutes = wrapper.vm.nightMinutesForSession({
        start: start.toISOString(),
        end: end.toISOString()
      })
      expect(minutes).toBe(240)
    })
  })

  // ─── Policy-driven aggregates ─────────────────────────────────
  describe('work policy', () => {
    it('exposes targetHours from the policy', async () => {
      api.getUserWorkPolicy.mockResolvedValue({ data: { data: POLICY } })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.targetHours).toBe(35)
      expect(wrapper.vm.targetWorkDays).toBe(5)
    })

    it('quotaPercentage is 0 without a policy', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.quotaPercentage).toBe(0)
    })

    it('quotaMessage explains the missing policy', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.quotaMessage).toContain('Aucune politique horaire')
    })

    it('balanceLabel is "Non configuré" without a policy', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.balanceLabel).toBe('Non configuré')
    })
  })

  describe('week aggregates with a policy', () => {
    beforeEach(() => {
      api.getUserWorkPolicy.mockResolvedValue({ data: { data: POLICY } })
    })

    it('weekHoursLabel reflects the current week', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: {
          data: [{ id: 1, start: '2026-09-22T09:00:00Z', end: '2026-09-22T17:00:00Z' }]
        }
      })
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.now = new Date('2026-09-22T18:00:00Z')
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.weekHoursLabel).toBe('8.0 h')
    })

    it('quotaPercentage caps at 100', async () => {
      api.getWorkingTimes.mockResolvedValue({
        data: {
          data: [
            { id: 1, start: '2026-09-21T09:00:00Z', end: '2026-09-21T22:00:00Z' },
            { id: 2, start: '2026-09-22T09:00:00Z', end: '2026-09-22T22:00:00Z' },
            { id: 3, start: '2026-09-23T09:00:00Z', end: '2026-09-23T22:00:00Z' }
          ]
        }
      })
      const wrapper = mountComponent()
      await flushPromises()
      wrapper.vm.now = new Date('2026-09-23T23:00:00Z')
      await wrapper.vm.$nextTick()
      expect(wrapper.vm.quotaPercentage).toBe(100)
    })

    it('balanceLabel shows a negative balance under 35h', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.balanceLabel).toMatch(/^-/)
    })

    it('nightWindowLabel uses the policy hours', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.nightWindowLabel).toBe('21:00 — 06:00')
    })
  })

  // ─── Clock in/out ─────────────────────────────────────────────
  describe('toggleClock', () => {
    it('calls clockInOut with the userId then reloads', async () => {
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      vi.clearAllMocks()
      api.getWorkingTimes.mockResolvedValue({ data: { data: [] } })

      await wrapper.vm.toggleClock()

      expect(api.clockInOut).toHaveBeenCalledWith(1)
      expect(api.getWorkingTimes).toHaveBeenCalled()
    })

    it('shows the "already clocked in" message on 409', async () => {
      api.clockInOut.mockRejectedValue({
        response: { data: { error: 'already clocked in' } }
      })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.toggleClock()
      expect(wrapper.vm.errorMessage).toBe('Une session est déjà en cours.')
    })

    it('shows a generic error on other failures', async () => {
      api.clockInOut.mockRejectedValue(new Error('boom'))
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.toggleClock()
      expect(wrapper.vm.errorMessage).toContain('n’a pas pu être enregistré')
    })

    it('clears isClocking after the call', async () => {
      api.clockInOut.mockResolvedValue({ data: {} })
      const wrapper = mountComponent()
      await flushPromises()
      await wrapper.vm.toggleClock()
      expect(wrapper.vm.isClocking).toBe(false)
    })
  })

  // ─── Formatting ───────────────────────────────────────────────
  describe('formatDuration', () => {
    it('shows minutes under 1 hour', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.formatDuration({
        start: '2026-09-22T09:00:00Z',
        end: '2026-09-22T09:45:00Z'
      })).toBe('45 min')
    })

    it('shows hours and minutes over 1 hour', async () => {
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.formatDuration({
        start: '2026-09-22T09:00:00Z',
        end: '2026-09-22T11:30:00Z'
      })).toBe('2h 30m')
    })
  })

  // ─── Recent sessions ──────────────────────────────────────────
  describe('recentSessions', () => {
    it('limits to 10 sessions', async () => {
      const many = Array.from({ length: 15 }, (_, i) => ({
        id: i + 1,
        start: `2026-09-${String(i + 1).padStart(2, '0')}T09:00:00Z`,
        end: `2026-09-${String(i + 1).padStart(2, '0')}T17:00:00Z`
      }))
      api.getWorkingTimes.mockResolvedValue({ data: { data: many } })
      const wrapper = mountComponent()
      await flushPromises()
      expect(wrapper.vm.recentSessions).toHaveLength(10)
    })
  })
})
