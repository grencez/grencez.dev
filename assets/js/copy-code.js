document.addEventListener('DOMContentLoaded', function() {
  const codeBlocks = document.querySelectorAll('.highlight');

  codeBlocks.forEach(function(block) {
    // Ignore the block if it's a <pre> element inside a .highlight container
    // This prevents duplicate buttons and ensures the button is attached to the wrapper
    if (block.tagName === 'PRE' && block.parentNode.classList.contains('highlight')) {
      return;
    }

    const button = document.createElement('button');
    button.className = 'copy-code-button';
    button.type = 'button';
    button.setAttribute('aria-label', 'Copy code to clipboard');
    // Text content is handled by CSS ::after pseudo-element to prevent selection

    button.addEventListener('click', function() {
      // Find the code element inside the block
      const code = block.querySelector('code');
      // If no code element (unlikely), fallback to block text
      const text = code ? code.innerText : block.innerText;

      navigator.clipboard.writeText(text).then(function() {
        button.classList.add('copied');
        button.setAttribute('aria-label', 'Copied successfully');

        setTimeout(function() {
          button.classList.remove('copied');
          button.setAttribute('aria-label', 'Copy code to clipboard');
        }, 2000);
      }, function(err) {
        console.error('Could not copy text: ', err);
        button.classList.add('error');
        button.setAttribute('aria-label', 'Error copying code');
      });
    });

    block.appendChild(button);
  });
});
