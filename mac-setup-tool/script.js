// Copy command to clipboard
function copyCommand(button) {
    const codeBlock = button.parentElement.querySelector('code');
    const text = codeBlock.textContent;
    
    navigator.clipboard.writeText(text).then(() => {
        const originalText = button.textContent;
        button.textContent = 'Copied!';
        button.classList.add('copied');
        
        setTimeout(() => {
            button.textContent = originalText;
            button.classList.remove('copied');
        }, 2000);
    });
}

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add active class to nav links based on scroll position
window.addEventListener('scroll', () => {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-links a');
    
    let current = '';
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (scrollY >= (sectionTop - 200)) {
            current = section.getAttribute('id');
        }
    });
    
    navLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href').slice(1) === current) {
            link.classList.add('active');
        }
    });
});

// Progress tracking
let completedSteps = JSON.parse(localStorage.getItem('completedSteps') || '[]');

function markStepComplete(stepId) {
    if (!completedSteps.includes(stepId)) {
        completedSteps.push(stepId);
        localStorage.setItem('completedSteps', JSON.stringify(completedSteps));
    }
    updateStepUI();
}

function updateStepUI() {
    document.querySelectorAll('.step-card').forEach((card, index) => {
        if (completedSteps.includes(`step-${index}`)) {
            card.classList.add('completed');
        }
    });
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    updateStepUI();
});