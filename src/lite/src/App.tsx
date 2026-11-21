import { courses, tracks, type Course } from './courses'
import './App.css'

function StatusBadge({ online }: { online: boolean }) {
  return (
    <span className={online ? 'badge online' : 'badge wip'}>
      {online ? '已上线' : '研发中'}
    </span>
  )
}

function CourseCard({ course }: { course: Course }) {
  return (
    <article className="card">
      <div className="cardTop">
        <h3>{course.name}</h3>
        <StatusBadge online={course.online} />
      </div>
      <span className="level">{course.level}</span>
      <p className="audience">{course.audience}</p>
      <p className="summary">{course.summary}</p>
      <div className="modules">
        {course.modules.map((module) => (
          <span key={module} className="module">
            {module}
          </span>
        ))}
      </div>
      {course.online && course.url && (
        <a className="go" href={course.url}>
          去上课 →
        </a>
      )}
    </article>
  )
}

export default function App() {
  return (
    <main className="page">
      <header className="hero">
        <h1>量潮课程云 · 课程清单</h1>
        <p>通识课程先行、领域课程在后，两段是先后关系；每门课标着上线状态。</p>
      </header>

      {tracks.map((group) => (
        <section key={group.track} aria-labelledby={`track-${group.track}`}>
          <div className="trackHead">
            <h2 id={`track-${group.track}`}>
              {group.track}课程 · {group.stage}
            </h2>
            <p>{group.note}</p>
          </div>
          <div className="grid">
            {courses
              .filter((course) => course.track === group.track)
              .map((course) => (
                <CourseCard key={course.name} course={course} />
              ))}
          </div>
        </section>
      ))}
    </main>
  )
}
