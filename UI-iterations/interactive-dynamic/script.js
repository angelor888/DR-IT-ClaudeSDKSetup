// interactive-dynamic Design Variation
// Interactive Features and Behaviors

document.addEventListener('DOMContentLoaded', function() {
    console.log('interactive-dynamic design variation loaded');
    
    // Initialize design-specific interactions
    initDesignInteractions();
    
    // Common interactions
    initCommonInteractions();
    
    // Performance monitoring
    initPerformanceMonitoring();
});

function initDesignInteractions() {
    const theme = 'interactive-dynamic';
    
    switch(theme) {
        case 'modern-minimal':
            initModernMinimalInteractions();
            break;
        case 'bold-creative':
            initBoldCreativeInteractions();
            break;
        case 'professional-business':
            initProfessionalBusinessInteractions();
            break;
        case 'interactive-dynamic':
            initInteractiveDynamicInteractions();
            break;
    }
}

function initCommonInteractions() {
    // Smooth scrolling
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });
    
    // Button click effects
    document.querySelectorAll('button').forEach(button => {
        button.addEventListener('click', function(e) {
            // Create ripple effect
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.width = ripple.style.height = size + 'px';
            ripple.style.left = x + 'px';
            ripple.style.top = y + 'px';
            ripple.classList.add('ripple');
            
            this.appendChild(ripple);
            
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
}

function initModernMinimalInteractions() {
    // Subtle parallax effects
    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        const parallaxElements = document.querySelectorAll('.hero-section');
        
        parallaxElements.forEach(element => {
            const speed = 0.5;
            element.style.transform = `translateY(${scrolled * speed}px)`;
        });
    });
    
    // Hover effects for cards
    document.querySelectorAll('.feature-card').forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
}

function initBoldCreativeInteractions() {
    // Dynamic background animation
    let hue = 0;
    setInterval(() => {
        hue = (hue + 1) % 360;
        document.documentElement.style.setProperty('--dynamic-hue', hue);
    }, 100);
    
    // Particle effects on click
    document.addEventListener('click', function(e) {
        createParticles(e.clientX, e.clientY);
    });
    
    // Animated text effects
    const titles = document.querySelectorAll('.hero-title');
    titles.forEach(title => {
        title.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.05) perspective(500px) rotateX(10deg)';
        });
        
        title.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1) perspective(500px) rotateX(15deg)';
        });
    });
}

function initProfessionalBusinessInteractions() {
    // Form validation and accessibility
    document.querySelectorAll('button').forEach(button => {
        button.addEventListener('focus', function() {
            this.style.outline = '2px solid #007bff';
            this.style.outlineOffset = '2px';
        });
        
        button.addEventListener('blur', function() {
            this.style.outline = 'none';
        });
    });
    
    // Keyboard navigation
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Tab') {
            document.body.classList.add('keyboard-navigation');
        }
    });
    
    document.addEventListener('mousedown', function() {
        document.body.classList.remove('keyboard-navigation');
    });
    
    // Loading states
    document.querySelectorAll('.primary-btn').forEach(button => {
        button.addEventListener('click', function() {
            this.innerHTML = 'Loading...';
            this.disabled = true;
            
            setTimeout(() => {
                this.innerHTML = 'Success!';
                this.style.background = '#28a745';
                
                setTimeout(() => {
                    this.innerHTML = 'Primary Action';
                    this.disabled = false;
                    this.style.background = '#007bff';
                }, 1000);
            }, 2000);
        });
    });
}

function initInteractiveDynamicInteractions() {
    // Mouse tracking effects
    document.addEventListener('mousemove', function(e) {
        const cursor = document.querySelector('.cursor') || createCursor();
        cursor.style.left = e.clientX + 'px';
        cursor.style.top = e.clientY + 'px';
    });
    
    // Intersection observer for animations
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -100px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.animation = 'fadeInUp 0.8s ease-out forwards';
            }
        });
    }, observerOptions);
    
    document.querySelectorAll('.feature-card').forEach(card => {
        observer.observe(card);
    });
    
    // Interactive background
    createInteractiveBackground();
    
    // Sound effects (optional)
    document.querySelectorAll('button').forEach(button => {
        button.addEventListener('click', function() {
            // Play sound effect if available
            playClickSound();
        });
    });
}

function createCursor() {
    const cursor = document.createElement('div');
    cursor.className = 'cursor';
    cursor.style.cssText = `
        position: fixed;
        width: 20px;
        height: 20px;
        background: radial-gradient(circle, #00d4ff, #ff00ff);
        border-radius: 50%;
        pointer-events: none;
        z-index: 9999;
        mix-blend-mode: screen;
        transition: transform 0.1s ease;
    `;
    document.body.appendChild(cursor);
    return cursor;
}

function createParticles(x, y) {
    for (let i = 0; i < 5; i++) {
        const particle = document.createElement('div');
        particle.style.cssText = `
            position: fixed;
            width: 6px;
            height: 6px;
            background: #ff6b6b;
            border-radius: 50%;
            left: ${x}px;
            top: ${y}px;
            pointer-events: none;
            z-index: 9999;
            animation: particleFloat 1s ease-out forwards;
        `;
        
        const angle = (i / 5) * Math.PI * 2;
        const velocity = 50 + Math.random() * 50;
        
        particle.style.setProperty('--dx', Math.cos(angle) * velocity + 'px');
        particle.style.setProperty('--dy', Math.sin(angle) * velocity + 'px');
        
        document.body.appendChild(particle);
        
        setTimeout(() => {
            particle.remove();
        }, 1000);
    }
}

function createInteractiveBackground() {
    const canvas = document.createElement('canvas');
    canvas.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        z-index: -1;
    `;
    document.body.appendChild(canvas);
    
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    const particles = [];
    
    function createBackgroundParticle() {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            vx: (Math.random() - 0.5) * 0.5,
            vy: (Math.random() - 0.5) * 0.5,
            size: Math.random() * 2 + 1,
            opacity: Math.random() * 0.5 + 0.1
        };
    }
    
    for (let i = 0; i < 50; i++) {
        particles.push(createBackgroundParticle());
    }
    
    function animateBackground() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        
        particles.forEach(particle => {
            particle.x += particle.vx;
            particle.y += particle.vy;
            
            if (particle.x < 0 || particle.x > canvas.width) particle.vx *= -1;
            if (particle.y < 0 || particle.y > canvas.height) particle.vy *= -1;
            
            ctx.beginPath();
            ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(0, 212, 255, ${particle.opacity})`;
            ctx.fill();
        });
        
        requestAnimationFrame(animateBackground);
    }
    
    animateBackground();
}

function playClickSound() {
    // Create audio context for sound effects
    try {
        const audioContext = new (window.AudioContext || window.webkitAudioContext)();
        const oscillator = audioContext.createOscillator();
        const gainNode = audioContext.createGain();
        
        oscillator.connect(gainNode);
        gainNode.connect(audioContext.destination);
        
        oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
        oscillator.frequency.exponentialRampToValueAtTime(400, audioContext.currentTime + 0.1);
        
        gainNode.gain.setValueAtTime(0.1, audioContext.currentTime);
        gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.1);
        
        oscillator.start(audioContext.currentTime);
        oscillator.stop(audioContext.currentTime + 0.1);
    } catch (e) {
        // Sound not supported
    }
}

function initPerformanceMonitoring() {
    // Performance metrics
    const startTime = performance.now();
    
    window.addEventListener('load', function() {
        const loadTime = performance.now() - startTime;
        console.log(`interactive-dynamic design loaded in ${loadTime.toFixed(2)}ms`);
        
        // Report to analytics if available
        if (typeof gtag !== 'undefined') {
            gtag('event', 'page_load_time', {
                event_category: 'Performance',
                event_label: 'interactive-dynamic',
                value: Math.round(loadTime)
            });
        }
    });
}

// CSS for animations
const style = document.createElement('style');
style.textContent = `
    @keyframes particleFloat {
        0% {
            transform: translate(0, 0);
            opacity: 1;
        }
        100% {
            transform: translate(var(--dx), var(--dy));
            opacity: 0;
        }
    }
    
    @keyframes fadeInUp {
        from {
            opacity: 0;
            transform: translateY(30px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    .ripple {
        position: absolute;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.6);
        animation: rippleEffect 0.6s ease-out;
        pointer-events: none;
    }
    
    @keyframes rippleEffect {
        0% {
            transform: scale(0);
            opacity: 1;
        }
        100% {
            transform: scale(4);
            opacity: 0;
        }
    }
    
    .keyboard-navigation button:focus {
        outline: 2px solid #007bff !important;
        outline-offset: 2px !important;
    }
`;
document.head.appendChild(style);
