document.addEventListener('DOMContentLoaded', function () {
  // Click-to-copy for ticket codes (.code-badge)
  const codeEls = document.querySelectorAll('.code-badge');
  if (codeEls.length) {
    codeEls.forEach(el => {
      el.addEventListener('click', async () => {
        const text = el.textContent.trim();
        try {
          await navigator.clipboard.writeText(text);
          el.classList.add('copied');
          const old = el.innerHTML;
          // show temporary label
          el.innerHTML = `${text} · Copied`;
          setTimeout(() => {
            el.classList.remove('copied');
            el.innerHTML = old;
          }, 1200);
        } catch (err) {
          // fallback: select text so user can copy manually
          const range = document.createRange();
          range.selectNodeContents(el);
          const sel = window.getSelection();
          sel.removeAllRanges();
          sel.addRange(range);
        }
      });
    });
  }

  // optional: add copy button next to code elements that aren't .code-badge
  document.querySelectorAll('.ticket-code').forEach(code => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'btn btn-sm btn-outline-secondary ms-2';
    btn.textContent = 'Copy';
    btn.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(code.textContent.trim());
        btn.textContent = 'Copied';
        setTimeout(() => btn.textContent = 'Copy', 1000);
      } catch (e) {
        // ignore
      }
    });
    code.parentNode.insertBefore(btn, code.nextSibling);
  });
});