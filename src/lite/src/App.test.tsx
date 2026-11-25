import '@testing-library/jest-dom/vitest'
import { render, screen, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import App from './App'
import { courses, tracks } from './courses'

describe('课程清单', () => {
  it('通识在前、领域在后，各成一级', () => {
    render(<App />)

    const headings = screen.getAllByRole('heading', { level: 2 })
    expect(headings.map((h) => h.textContent)).toEqual([
      '通识课程 · 大一',
      '领域课程 · 大三',
    ])
    expect(tracks.map((t) => t.track)).toEqual(['通识', '领域'])
  })

  it('每门课都标上线状态', () => {
    render(<App />)

    expect(screen.getAllByText('已上线')).toHaveLength(3)
    expect(screen.getAllByText('研发中')).toHaveLength(5)
  })

  it('通识顺序：AI创意 → AI办公 → AI编程 → AI教学', () => {
    const names = courses
      .filter((course) => course.track === '通识')
      .map((course) => course.name)

    expect(names).toEqual(['AI创意', 'AI办公', 'AI编程', 'AI教学'])
  })

  it('已上线给学员端入口，研发中的不给', () => {
    render(<App />)

    const links = screen.getAllByRole('link', { name: /去上课/ })
    expect(links).toHaveLength(3)
    for (const link of links) {
      expect(link).toHaveAttribute('href', 'https://lite.class.quanttide.com/')
    }

    // AI教学在研发中，计划上线到本清单，学员端还没课时——不给入口
    const teachingCard = screen.getByText('AI教学').closest('article') as HTMLElement
    expect(within(teachingCard).queryByRole('link')).toBeNull()
    expect(within(teachingCard).getByText('研发中')).toBeInTheDocument()

    const wipCard = screen
      .getByText('大数据导论')
      .closest('article') as HTMLElement
    expect(within(wipCard).queryByRole('link')).toBeNull()
    expect(within(wipCard).getByText('研发中')).toBeInTheDocument()
  })

  it('领域四门都在清单里，没有被藏掉', () => {
    const domain = courses.filter((course) => course.track === '领域')

    expect(domain.map((course) => course.name)).toEqual([
      '知识工作',
      '大数据导论',
      '数据工程',
      '生产实习',
    ])
  })
})
