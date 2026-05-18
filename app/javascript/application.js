// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const siteNavigation = [
  { path: "/#recommendations", matches: ["/"] },
  { path: "/search-results", matches: ["/search-results"] },
  { path: "/saved", matches: ["/saved"] },
  { path: "/post-sublet", matches: ["/post-sublet"] },
  { path: "/profile", matches: ["/profile"] },
]

const ignoredArrowTargets = [
  "a",
  "button",
  "input",
  "select",
  "textarea",
  "[contenteditable='true']",
  "[role='button']",
  "[role='tab']",
  "[role='tabpanel']",
  "[data-favorite-carousel]",
  "[data-favorite-listings]",
  ".date-picker-nav",
  ".date-picker-day",
  ".date-input",
  ".date-value",
  ".date-filter-input",
  ".date-filter-toggle",
]

const currentNavigationIndex = () => {
  const currentPath = window.location.pathname.replace(/\/$/, "") || "/"

  return siteNavigation.findIndex((item) => item.matches.includes(currentPath))
}

const visitNavigationPath = (path) => {
  if (window.Turbo) {
    window.Turbo.visit(path)
    return
  }

  window.location.assign(path)
}

document.addEventListener("keydown", (event) => {
  if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return
  if (!["ArrowLeft", "ArrowRight"].includes(event.key)) return
  if (event.target instanceof Element && event.target.closest(ignoredArrowTargets.join(","))) return

  const currentIndex = currentNavigationIndex()
  if (currentIndex === -1) return

  const direction = event.key === "ArrowRight" ? 1 : -1
  const nextIndex = (currentIndex + direction + siteNavigation.length) % siteNavigation.length

  event.preventDefault()
  visitNavigationPath(siteNavigation[nextIndex].path)
})

document.addEventListener("turbo:before-visit", () => {
  document.body.classList.add("is-page-leaving")
})

document.addEventListener("turbo:load", () => {
  document.body.classList.remove("is-page-leaving")
})

document.addEventListener("turbo:before-cache", () => {
  document.body.classList.remove("is-page-leaving")
})
