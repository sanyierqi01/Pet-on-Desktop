const storageKey = "codex-todo-list";
const taskForm = document.querySelector("#taskForm");
const taskInput = document.querySelector("#taskInput");
const taskList = document.querySelector("#taskList");
const template = document.querySelector("#taskTemplate");
const filters = document.querySelectorAll(".filter");
const remainingText = document.querySelector("#remainingText");
const doneCount = document.querySelector("#doneCount");
const totalCount = document.querySelector("#totalCount");
const clearDone = document.querySelector("#clearDone");
const progress = document.querySelector(".progress");

let tasks = loadTasks();
let currentFilter = "all";

function loadTasks() {
  try {
    return JSON.parse(localStorage.getItem(storageKey)) || [];
  } catch {
    return [];
  }
}

function saveTasks() {
  localStorage.setItem(storageKey, JSON.stringify(tasks));
}

function createId() {
  if (crypto.randomUUID) {
    return crypto.randomUUID();
  }

  return `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function visibleTasks() {
  if (currentFilter === "active") {
    return tasks.filter((task) => !task.done);
  }

  if (currentFilter === "done") {
    return tasks.filter((task) => task.done);
  }

  return tasks;
}

function renderTasks() {
  taskList.innerHTML = "";

  visibleTasks().forEach((task) => {
    const item = template.content.firstElementChild.cloneNode(true);
    const checkbox = item.querySelector(".task-check");
    const title = item.querySelector(".task-title");
    const deleteButton = item.querySelector(".delete-btn");

    item.classList.toggle("done", task.done);
    checkbox.checked = task.done;
    title.textContent = task.title;

    checkbox.addEventListener("change", () => {
      task.done = checkbox.checked;
      saveTasks();
      renderTasks();
    });

    deleteButton.addEventListener("click", () => {
      tasks = tasks.filter((candidate) => candidate.id !== task.id);
      saveTasks();
      renderTasks();
    });

    taskList.appendChild(item);
  });

  updateStats();
}

function updateStats() {
  const done = tasks.filter((task) => task.done).length;
  const total = tasks.length;
  const active = total - done;
  const percent = total === 0 ? 0 : Math.round((done / total) * 100);

  doneCount.textContent = done;
  totalCount.textContent = total;
  progress.style.setProperty("--progress", `${percent}%`);
  remainingText.textContent =
    total === 0 ? "No tasks yet" : `${active} active, ${done} done`;
  clearDone.disabled = done === 0;
}

taskForm.addEventListener("submit", (event) => {
  event.preventDefault();
  const title = taskInput.value.trim();

  if (!title) {
    taskInput.focus();
    return;
  }

  tasks.unshift({
    id: createId(),
    title,
    done: false,
  });

  taskInput.value = "";
  saveTasks();
  renderTasks();
});

filters.forEach((filterButton) => {
  filterButton.addEventListener("click", () => {
    currentFilter = filterButton.dataset.filter;
    filters.forEach((button) => {
      button.classList.toggle("active", button === filterButton);
    });
    renderTasks();
  });
});

clearDone.addEventListener("click", () => {
  tasks = tasks.filter((task) => !task.done);
  saveTasks();
  renderTasks();
});

renderTasks();
