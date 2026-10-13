import { beforeEach, describe, expect, it, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Authentication from '@/components/Authentication.vue'
import api from '@/services/api'
import { writeAuthCsrfToken, writeAuthToken, writeAuthUser } from '@/utils/auth'

vi.mock('@/services/api', () => ({
  default: { post: vi.fn() }
}))

vi.mock('@/utils/auth', () => ({
  writeAuthCsrfToken: vi.fn(),
  writeAuthToken: vi.fn(),
  writeAuthUser: vi.fn()
}))

describe('Authentication.vue', () => {
  const router = { push: vi.fn() }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('persists the forced-password-change flag and routes to the change form', async () => {
    api.post.mockResolvedValue({
      data: {
        user: {
          id: 12,
          username: 'New employee',
          role: 'employee',
          must_change_password: true
        },
        token: 'jwt-token',
        csrf_token: 'csrf-token'
      }
    })

    const wrapper = mount(Authentication, {
      global: {
        mocks: { $router: router },
        stubs: { AuthShell: { template: '<div><slot /></div>' } }
      }
    })
    wrapper.vm.email = 'employee@example.com'
    wrapper.vm.password = 'temporary-password'

    await wrapper.vm.submit()

    expect(writeAuthToken).toHaveBeenCalledWith('jwt-token')
    expect(writeAuthCsrfToken).toHaveBeenCalledWith('csrf-token')
    expect(writeAuthUser).toHaveBeenCalledWith(expect.objectContaining({
      id: 12,
      must_change_password: true
    }))
    expect(router.push).toHaveBeenCalledWith('/change-password')
  })
})
