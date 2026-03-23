/**
 * Claude Task Runner - Frontend JavaScript
 */

// API Base URL
const API_BASE = '/api';

// State
let currentPage = 1;
let currentFilter = '';

// DOM Elements
const taskForm = document.getElementById('task-form');
const tasksTbody = document.getElementById('tasks-tbody');
const statusFilter = document.getElementById('status-filter');
const refreshBtn = document.getElementById('refresh-btn');
const pagination = document.getElementById('pagination');
const taskModal = document.getElementById('task-modal');
const modalClose = document.getElementById('modal-close');
const modalBody = document.getElementById('modal-body');
const toast = document.getElementById('toast');

// Stats elements
const statPending = document.getElementById('stat-pending');
const statRunning = document.getElementById('stat-running');
const statCompleted = document.getElementById('stat-completed');
const statFailed = document.getElementById('stat-failed');

// ==================== Utility Functions ====================

function showToast(message, type = 'info') {
    toast.textContent = message;
    toast.className = 'toast show ' + type;
    setTimeout(() => {
        toast.className = 'toast';
    }, 3000);
}

function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString('zh-CN');
}

function truncate(str, length = 50) {
    if (!str) return '';
    return str.length > length ? str.substring(0, length) + '...' : str;
}

function getStatusBadge(status) {
    const statusMap = {
        pending: { label: '等待中', class: 'status-pending' },
        running: { label: '执行中', class: 'status-running' },
        completed: { label: '已完成', class: 'status-completed' },
        failed: { label: '失败', class: 'status-failed' },
        cancelled: { label: '已取消', class: 'status-cancelled' },
    };
    const info = statusMap[status] || { label: status, class: '' };
    return `<span class="status-badge ${info.class}">${info.label}</span>`;
}

// ==================== API Calls ====================

async function fetchAPI(endpoint, options = {}) {
    const response = await fetch(API_BASE + endpoint, {
        headers: {
            'Content-Type': 'application/json',
        },
        ...options,
    });
    
    if (!response.ok) {
        const error = await response.json().catch(() => ({ detail: 'Unknown error' }));
        throw new Error(error.detail || 'Request failed');
    }
    
    return response.json();
}

async function loadStats() {
    try {
        const stats = await fetchAPI('/stats');
        statPending.textContent = stats.pending;
        statRunning.textContent = stats.running;
        statCompleted.textContent = stats.completed;
        statFailed.textContent = stats.failed;
    } catch (error) {
        console.error('Failed to load stats:', error);
    }
}

async function loadTasks(page = 1, status = '') {
    try {
        let endpoint = `/tasks?page=${page}&page_size=10`;
        if (status) {
            endpoint += `&status=${status}`;
        }
        
        const data = await fetchAPI(endpoint);
        renderTasks(data.tasks);
        renderPagination(data.total, data.page, data.page_size);
    } catch (error) {
        console.error('Failed to load tasks:', error);
        showToast('加载任务失败: ' + error.message, 'error');
    }
}

async function createTask(formData) {
    const data = {
        prompt: formData.get('prompt'),
    };
    
    if (formData.get('working_directory')) {
        data.working_directory = formData.get('working_directory');
    }
    if (formData.get('timeout')) {
        data.timeout = parseInt(formData.get('timeout'));
    }
    if (formData.get('callback_url')) {
        data.callback_url = formData.get('callback_url');
    }
    
    return fetchAPI('/tasks', {
        method: 'POST',
        body: JSON.stringify(data),
    });
}

async function deleteTask(taskId) {
    return fetchAPI(`/tasks/${taskId}`, {
        method: 'DELETE',
    });
}

async function getTask(taskId) {
    return fetchAPI(`/tasks/${taskId}`);
}

// ==================== Render Functions ====================

function renderTasks(tasks) {
    if (tasks.length === 0) {
        tasksTbody.innerHTML = `
            <tr>
                <td colspan="5" class="empty-state">暂无任务</td>
            </tr>
        `;
        return;
    }
    
    tasksTbody.innerHTML = tasks.map(task => `
        <tr>
            <td class="task-id">${task.id.substring(0, 8)}...</td>
            <td class="task-prompt" title="${task.prompt}">${truncate(task.prompt)}</td>
            <td>${getStatusBadge(task.status)}</td>
            <td>${formatDate(task.created_at)}</td>
            <td>
                <div class="action-btns">
                    <button class="btn btn-secondary btn-sm" onclick="viewTask('${task.id}')">查看</button>
                    ${task.status !== 'running' ? `
                        <button class="btn btn-danger btn-sm" onclick="confirmDelete('${task.id}')">删除</button>
                    ` : ''}
                </div>
            </td>
        </tr>
    `).join('');
}

function renderPagination(total, page, pageSize) {
    const totalPages = Math.ceil(total / pageSize);
    
    if (totalPages <= 1) {
        pagination.innerHTML = '';
        return;
    }
    
    let buttons = [];
    
    // Previous button
    if (page > 1) {
        buttons.push(`<button onclick="goToPage(${page - 1})">上一页</button>`);
    }
    
    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === page) {
            buttons.push(`<button class="active">${i}</button>`);
        } else if (i === 1 || i === totalPages || Math.abs(i - page) <= 2) {
            buttons.push(`<button onclick="goToPage(${i})">${i}</button>`);
        } else if (i === page - 3 || i === page + 3) {
            buttons.push(`<button disabled>...</button>`);
        }
    }
    
    // Next button
    if (page < totalPages) {
        buttons.push(`<button onclick="goToPage(${page + 1})">下一页</button>`);
    }
    
    pagination.innerHTML = buttons.join('');
}

async function viewTask(taskId) {
    try {
        const task = await getTask(taskId);
        
        modalBody.innerHTML = `
            <div class="task-detail">
                <div class="detail-row">
                    <strong>ID:</strong>
                    <code>${task.id}</code>
                </div>
                <div class="detail-row">
                    <strong>状态:</strong>
                    ${getStatusBadge(task.status)}
                </div>
                <div class="detail-row">
                    <strong>创建时间:</strong>
                    ${formatDate(task.created_at)}
                </div>
                <div class="detail-row">
                    <strong>开始时间:</strong>
                    ${formatDate(task.started_at)}
                </div>
                <div class="detail-row">
                    <strong>完成时间:</strong>
                    ${formatDate(task.completed_at)}
                </div>
                <div class="detail-row">
                    <strong>工作目录:</strong>
                    ${task.working_directory || '-'}
                </div>
                <div class="detail-row">
                    <strong>超时时间:</strong>
                    ${task.timeout ? task.timeout + ' 秒' : '-'}
                </div>
                <div class="detail-section">
                    <strong>提示词:</strong>
                    <pre>${task.prompt}</pre>
                </div>
                ${task.result ? `
                    <div class="detail-section">
                        <strong>执行结果:</strong>
                        <pre>${task.result}</pre>
                    </div>
                ` : ''}
                ${task.error ? `
                    <div class="detail-section error">
                        <strong>错误信息:</strong>
                        <pre style="color: var(--danger-color);">${task.error}</pre>
                    </div>
                ` : ''}
            </div>
        `;
        
        taskModal.classList.add('active');
    } catch (error) {
        showToast('获取任务详情失败: ' + error.message, 'error');
    }
}

async function confirmDelete(taskId) {
    if (!confirm('确定要删除这个任务吗？')) {
        return;
    }
    
    try {
        await deleteTask(taskId);
        showToast('任务已删除', 'success');
        loadTasks(currentPage, currentFilter);
        loadStats();
    } catch (error) {
        showToast('删除失败: ' + error.message, 'error');
    }
}

function goToPage(page) {
    currentPage = page;
    loadTasks(page, currentFilter);
}

// ==================== Event Listeners ====================

taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = new FormData(taskForm);
    const submitBtn = taskForm.querySelector('button[type="submit"]');
    const btnText = submitBtn.querySelector('.btn-text');
    const btnLoading = submitBtn.querySelector('.btn-loading');
    
    // Show loading state
    submitBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoading.style.display = 'inline';
    
    try {
        const task = await createTask(formData);
        showToast('任务已创建: ' + task.id.substring(0, 8), 'success');
        taskForm.reset();
        document.getElementById('timeout').value = '300';
        loadTasks(1, currentFilter);
        loadStats();
        currentPage = 1;
    } catch (error) {
        showToast('创建失败: ' + error.message, 'error');
    } finally {
        submitBtn.disabled = false;
        btnText.style.display = 'inline';
        btnLoading.style.display = 'none';
    }
});

statusFilter.addEventListener('change', (e) => {
    currentFilter = e.target.value;
    currentPage = 1;
    loadTasks(1, currentFilter);
});

refreshBtn.addEventListener('click', () => {
    loadTasks(currentPage, currentFilter);
    loadStats();
});

modalClose.addEventListener('click', () => {
    taskModal.classList.remove('active');
});

taskModal.addEventListener('click', (e) => {
    if (e.target === taskModal) {
        taskModal.classList.remove('active');
    }
});

// ==================== Initialize ====================

// Initial load
loadStats();
loadTasks();

// Auto refresh every 10 seconds
setInterval(() => {
    loadStats();
    loadTasks(currentPage, currentFilter);
}, 10000);
