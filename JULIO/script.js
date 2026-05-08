/** 
 * ==========================================
 * script.js — Portafolio "The Spatial Nexus"
 * ==========================================
 */

document.addEventListener('DOMContentLoaded', () => {
    initNavigation();
    // initVoronoi();
    initCounters();
    cargarProyectos();
});

/** 
 * 1. NAVEGACIÓN ACTIVA Y SCROLL
 */
function initNavigation() {
    const sections = document.querySelectorAll('section[id]');
    const navLinks = document.querySelectorAll('.nav-link');
    const scrollBtn = document.getElementById('scrollTop');

    window.addEventListener('scroll', () => {
        let current = "";
        sections.forEach(section => {
            const sectionTop = section.offsetTop;
            const sectionHeight = section.clientHeight;
            if (pageYOffset >= sectionTop - 150) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href').includes(current)) {
                link.classList.add('active');
            }
        });

        if (scrollBtn) {
            scrollBtn.classList.toggle('visible', window.scrollY > 500);
        }
    });

    scrollBtn?.addEventListener('click', () => {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });
}

/** 
 * 2. FONDO INTERACTIVO: RED ESPACIAL (Triangulación Dinámica)
 */
function initVoronoi() {
    const canvas = document.getElementById('voronoi-canvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');

    let particles = [];
    const particleCount = 60;
    const connectionDist = 180;
    let mouse = { x: -1000, y: -1000 };

    function resize() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }

    class Particle {
        constructor() {
            this.x = Math.random() * canvas.width;
            this.y = Math.random() * canvas.height;
            this.vx = (Math.random() - 0.5) * 0.8;
            this.vy = (Math.random() - 0.5) * 0.8;
            this.size = Math.random() * 2 + 1;
        }

        update() {
            this.x += this.vx;
            this.y += this.vy;

            if (this.x < 0 || this.x > canvas.width) this.vx *= -1;
            if (this.y < 0 || this.y > canvas.height) this.vy *= -1;

            // Interacción suave con el mouse
            const dx = mouse.x - this.x;
            const dy = mouse.y - this.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 200) {
                this.x -= dx * 0.01;
                this.y -= dy * 0.01;
            }
        }

        draw() {
            ctx.beginPath();
            ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
            ctx.fillStyle = '#00f2ff';
            ctx.fill();
        }
    }

    function init() {
        particles = [];
        for (let i = 0; i < particleCount; i++) {
            particles.push(new Particle());
        }
    }

    function animate() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        for (let i = 0; i < particles.length; i++) {
            particles[i].update();
            particles[i].draw();

            for (let j = i + 1; j < particles.length; j++) {
                const dx = particles[i].x - particles[j].x;
                const dy = particles[i].y - particles[j].y;
                const dist = Math.sqrt(dx * dx + dy * dy);

                if (dist < connectionDist) {
                    ctx.beginPath();
                    ctx.strokeStyle = `rgba(0, 242, 255, ${1 - dist / connectionDist})`;
                    ctx.lineWidth = 0.5;
                    ctx.moveTo(particles[i].x, particles[i].y);
                    ctx.lineTo(particles[j].x, particles[j].y);
                    ctx.stroke();
                }
            }
        }
        requestAnimationFrame(animate);
    }

    window.addEventListener('resize', resize);
    window.addEventListener('mousemove', (e) => {
        mouse.x = e.clientX;
        mouse.y = e.clientY;
    });

    resize();
    init();
    animate();
}

/** 
 * 3. ANIMACIONES DE CONTEO (STARS)
 */
function initCounters() {
    const stats = document.querySelectorAll('.stat-val');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const target = +entry.target.getAttribute('data-target');
                animateValue(entry.target, 0, target, 2000);
                observer.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    stats.forEach(stat => observer.observe(stat));
}

function animateValue(obj, start, end, duration) {
    let startTimestamp = null;
    const step = (timestamp) => {
        if (!startTimestamp) startTimestamp = timestamp;
        const progress = Math.min((timestamp - startTimestamp) / duration, 1);
        obj.innerHTML = Math.floor(progress * (end - start) + start);
        if (progress < 1) {
            window.requestAnimationFrame(step);
        }
    };
    window.requestAnimationFrame(step);
}

/** 
 * 4. CARGA DINÁMICA DE PROYECTOS (BENTO STYLE)
 */
async function cargarProyectos() {
    const container = document.getElementById('portfolio-container');
    if (!container) return;

    try {
        const timestamp = new Date().getTime();
        const response = await fetch(`manifest.json?v=${timestamp}`);
        if (!response.ok) throw new Error('Error manifest');
        const proyectos = await response.json();

        container.innerHTML = '';
        proyectos.forEach((p, idx) => {
            const card = crearTarjetaNexus(p, idx);
            container.appendChild(card);
        });

        inicializarFiltrosNexus();

    } catch (error) {
        console.error(error);
        container.innerHTML = `<div class="col-12 text-center text-danger">Error al sincronizar datos espaciales.</div>`;
    }
}

function crearTarjetaNexus(p, idx) {
    const col = document.createElement('div');
    col.className = `col-lg-4 col-md-6 card-item nx-item`;
    
    // Dataset type basado en extensiones para los nuevos filtros
    let types = [];
    if (p.pdf) types.push('pdf');
    if (p.zip) types.push('zip');
    if (p.r) types.push('r');
    if (p.html) types.push('html');
    if (p.thumbnail || p.img) types.push('img');
    col.dataset.type = types.join(' ');

    // Generar Badges de extensiones (esquina superior izquierda en imagen)
    let extBadges = '';
    if (p.pdf) extBadges += `<span class="badge-ext badge-pdf"><i class="bi bi-file-pdf"></i> PDF</span> `;
    if (p.r) extBadges += `<span class="badge-ext badge-r"><i class="bi bi-code-slash"></i> R</span> `;
    if (p.html) extBadges += `<span class="badge-ext badge-html"><i class="bi bi-globe"></i> HTML</span> `;
    if (p.zip) extBadges += `<span class="badge-ext badge-zip"><i class="bi bi-file-zip"></i> ZIP</span> `;

    // Generar Botones específicos
    let buttons = '';
    if (p.pdf) {
        buttons += `<button onclick="abrirVisor('${p.pdf}', ${idx})" class="btn-ext btn-ext-pdf"><i class="bi bi-file-earmark-pdf"></i> Ver PDF</button>`;
    }
    if (p.r) {
        buttons += `<button onclick="window.open('${p.r}', '_blank')" class="btn-ext btn-ext-r"><i class="bi bi-github"></i> Código R</button>`;
    }
    if (p.html) {
        const btnLabel = p.tags && p.tags.includes('shiny') ? 'Ver Dashboard' : 'Ver Mapas';
        buttons += `<button onclick="abrirHTML('${p.html}', ${idx})" class="btn-ext btn-ext-html"><i class="bi bi-globe"></i> ${btnLabel}</button>`;
    }
    if (p.zip) {
        buttons += `<button onclick="window.open('${p.zip}', '_blank')" class="btn-ext btn-ext-zip"><i class="bi bi-file-zip"></i> Proyect ZIP</button>`;
    }

    // Generar Miniatura si existe
    let thumbnailHtml = '';
    if (p.thumbnail || p.img) {
        const imgSrc = p.thumbnail || p.img;
        thumbnailHtml = `<div style="height: 180px; overflow: hidden; border-bottom: 1px solid #f1f5f9;">
                            <img src="${imgSrc}" alt="${p.title}" style="width: 100%; height: 100%; object-fit: cover;">
                         </div>`;
    }

    col.innerHTML = `
        <div class="portfolio-card style-clean animate__animated animate__fadeInUp" style="animation-delay: ${idx * 0.1}s">
            <div class="card-top-line"></div>
            ${thumbnailHtml}
            <div class="card-nexus-body d-flex flex-column h-100">
                <div class="d-flex gap-2 flex-wrap mb-3">
                    ${extBadges}
                </div>
                <h4 class="fw-bold mb-3">${p.title}</h4>
                <p class="text-muted small mb-4 flex-grow-1">${p.description}</p>
                <div class="d-flex gap-2 flex-wrap mt-auto">
                    ${buttons}
                </div>
            </div>
        </div>
    `;
    return col;
}

function inicializarFiltrosNexus() {
    const btns = document.querySelectorAll('.filter-btn-nx');
    const items = document.querySelectorAll('.nx-item');

    btns.forEach(btn => {
        btn.addEventListener('click', () => {
            btns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');

            const filter = btn.dataset.filter;
            items.forEach(item => {
                const match = filter === 'all' || item.dataset.type.includes(filter);
                if (match) {
                    item.style.display = 'block';
                    item.classList.add('animate__fadeIn');
                } else {
                    item.style.display = 'none';
                }
            });
        });
    });
}

/** 
 * 5. MODALES (RE-USE LOGIC FROM ORIGINAL BUT MATCH STYLING)
 */
let pdfInstance = null;
let currentZoom = 1.0;
let pdfDoc = null;
let pageFlip = null;

window.abrirVisor = async function (pdfUrl) {
    const modal = document.getElementById("modalPDF");
    modal.style.display = "flex";
    setTimeout(() => modal.classList.add("active"), 10);
    document.body.style.overflow = "hidden";

    const flipBook = document.getElementById("flipBook");
    const flipLoading = document.getElementById("flipLoading");
    const zoomLevel = document.getElementById("zoomLevel");
    const btnDownload = document.getElementById("btnDownload");

    flipBook.innerHTML = "";
    flipLoading.style.display = "flex";
    currentZoom = 1.0;
    if (zoomLevel) zoomLevel.innerText = "100%";
    if (btnDownload) btnDownload.onclick = () => window.open(pdfUrl, '_blank');

    try {
        if (typeof pdfjsLib === 'undefined') return;

        pdfjsLib.GlobalWorkerOptions.workerSrc = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/2.16.105/pdf.worker.min.js";
        pdfDoc = await pdfjsLib.getDocument(pdfUrl).promise;

        const pages = [];
        const scale = 2.0; // Render at higher scale for clarity

        for (let i = 1; i <= pdfDoc.numPages; i++) {
            const page = await pdfDoc.getPage(i);
            const viewport = page.getViewport({ scale });
            const canvas = document.createElement("canvas");
            const context = canvas.getContext("2d");
            canvas.height = viewport.height;
            canvas.width = viewport.width;
            await page.render({ canvasContext: context, viewport: viewport }).promise;

            const div = document.createElement("div");
            div.className = "page"; // Class for page-flip
            div.appendChild(canvas);
            pages.push(div);
        }

        if (typeof St !== 'undefined' && St.PageFlip) {
            if (pageFlip) pageFlip.destroy();
            
            // Dimensiones más amplias para pantallas modernas
            const w = window.innerWidth > 1400 ? 700 : 550;
            const h = window.innerWidth > 1400 ? 950 : 800;

            pageFlip = new St.PageFlip(flipBook, {
                width: w, 
                height: h,
                size: "stretch",
                showCover: false,
                useMouseOver: false,
                flippingTime: 1000,
                mobileScrollSupport: false
            });
            
            pageFlip.loadFromHTML(pages);
            
            // Listeners para botones de navegación
            document.getElementById('flipPrev').onclick = () => pageFlip.flipPrev();
            document.getElementById('flipNext').onclick = () => pageFlip.flipNext();
            
            // Actualizar info de página
            pageFlip.on('flip', (e) => {
                const info = document.getElementById('flipInfo');
                if (info) info.innerText = `Página ${e.data + 1} de ${pdfDoc.numPages}`;
            });
            
            // Inicializar info
            const info = document.getElementById('flipInfo');
            if (info) info.innerText = `Página 1 de ${pdfDoc.numPages}`;

        } else {
            pages.forEach(p => flipBook.appendChild(p));
            flipBook.style.overflowY = "auto";
            flipBook.style.height = "80vh";
        }

        initZoomControls();
        flipLoading.style.display = "none";
    } catch (e) {
        console.error(e);
        flipLoading.innerHTML = "Error al proyectar PDF";
    }
};

function initZoomControls() {
    const zin = document.getElementById('zoomIn');
    const zout = document.getElementById('zoomOut');
    
    if (zin) zin.onclick = () => changeZoom(0.1);
    if (zout) zout.onclick = () => changeZoom(-0.1);
}

function changeZoom(delta) {
    currentZoom = Math.min(Math.max(currentZoom + delta, 0.5), 3.0);
    const zoomLabel = document.getElementById('zoomLevel');
    const flipZoomWrap = document.getElementById('flipZoomWrap');
    
    if (zoomLabel) zoomLabel.innerText = `${Math.round(currentZoom * 100)}%`;
    if (flipZoomWrap) {
        flipZoomWrap.style.transform = `scale(${currentZoom})`;
    }
}



window.cerrarVisor = function () {
    const modal = document.getElementById("modalPDF");
    modal.classList.remove("active");
    if (pageFlip) {
        pageFlip.destroy();
        pageFlip = null;
    }
    setTimeout(() => { modal.style.display = "none"; document.body.style.overflow = ""; }, 300);
};

window.abrirHTML = function (ruta) {
    const modal = document.getElementById("modalHTML");
    const visor = document.getElementById("visorHTML");
    const loading = document.getElementById("htmlLoading");

    visor.src = "";
    loading.style.display = "flex";
    modal.style.display = "flex";
    setTimeout(() => modal.classList.add("active"), 10);
    document.body.style.overflow = "hidden";

    const cacheBuster = new Date().getTime();
    const urlConCacheBuster = ruta.includes('?') ? `${ruta}&v=${cacheBuster}` : `${ruta}?v=${cacheBuster}`;
    visor.src = urlConCacheBuster;

    visor.onload = () => loading.style.display = "none";
};

window.cerrarHTML = function () {
    const modal = document.getElementById("modalHTML");
    modal.classList.remove("active");
    setTimeout(() => { modal.style.display = "none"; document.body.style.overflow = ""; }, 300);
};

window.abrirNuevaPestana = function () {
    const visor = document.getElementById("visorHTML");
    if (visor && visor.getAttribute('src')) {
        window.open(visor.getAttribute('src'), '_blank');
    }
};

// Tooltip / Interaction ESC
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        cerrarVisor();
        cerrarHTML();
    }
});