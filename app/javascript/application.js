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

let conversationSocket

const escapeHtml = (value) => {
  const element = document.createElement("span")
  element.textContent = value
  return element.innerHTML
}

const appendChatMessage = (message) => {
  const messageList = document.querySelector("[data-message-list]")
  const chatPage = document.querySelector("[data-conversation-id]")
  if (!messageList || !chatPage || messageList.querySelector(`[data-message-id="${message.id}"]`)) return

  const currentUserId = Number(chatPage.dataset.currentUserId)
  const ownMessage = Number(message.sender_id) === currentUserId
  const article = document.createElement("article")
  article.className = `message-bubble ${ownMessage ? "is-own-message" : "is-other-message"}`
  article.dataset.messageId = message.id
  const datetimeAttribute = message.created_at_iso ? ` datetime="${escapeHtml(message.created_at_iso)}"` : ""
  article.innerHTML = `
    <p class="message-meta">
      <span>${escapeHtml(message.sender_name)}</span>
      <time${datetimeAttribute}>${escapeHtml(message.created_at)}</time>
    </p>
    <p class="message-body">${escapeHtml(message.body)}</p>
  `

  messageList.append(article)
  messageList.scrollTop = messageList.scrollHeight
}

const disconnectConversationSocket = () => {
  if (!conversationSocket) return

  conversationSocket.close()
  conversationSocket = undefined
}

const connectConversationSocket = () => {
  disconnectConversationSocket()

  const chatPage = document.querySelector("[data-conversation-id]")
  if (!chatPage) return

  const protocol = window.location.protocol === "https:" ? "wss" : "ws"
  const identifier = JSON.stringify({
    channel: "ConversationChannel",
    conversation_id: chatPage.dataset.conversationId,
  })

  conversationSocket = new WebSocket(`${protocol}://${window.location.host}/cable`)

  conversationSocket.addEventListener("open", () => {
    conversationSocket.send(JSON.stringify({ command: "subscribe", identifier }))
  })

  conversationSocket.addEventListener("message", (event) => {
    const payload = JSON.parse(event.data)
    if (!payload.message) return

    appendChatMessage(payload.message)
  })
}

const bindChatForm = () => {
  const form = document.querySelector("[data-chat-form]")
  if (!form) return

  const input = form.querySelector("[data-message-input]")

  input?.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" || event.shiftKey || event.altKey || event.ctrlKey || event.metaKey) return

    event.preventDefault()
    form.requestSubmit()
  })

  form.addEventListener("submit", async (event) => {
    event.preventDefault()

    const submit = form.querySelector("input[type='submit']")
    const body = input?.value.trim()
    if (!body) return

    submit?.setAttribute("disabled", "disabled")

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: new FormData(form),
        headers: { Accept: "application/json" },
      })

      if (response.ok && input) input.value = ""
      if (!response.ok) form.submit()
    } catch (_error) {
      form.submit()
    } finally {
      submit?.removeAttribute("disabled")
    }
  })
}

document.addEventListener("turbo:load", () => {
  connectConversationSocket()
  bindChatForm()

  const messageList = document.querySelector("[data-message-list]")
  if (messageList) messageList.scrollTop = messageList.scrollHeight
})

document.addEventListener("turbo:before-cache", disconnectConversationSocket)
