document.addEventListener('DOMContentLoaded', function() {
  const codeBlocks = document.querySelectorAll('.highlight');

  codeBlocks.forEach(function(block) {
    const button = document.createElement('button');
    button.className = 'copy-code-button';
    button.type = 'button';
    button.innerText = 'Copy';

    button.addEventListener('click', function() {
      // Find the code element inside the block
      const code = block.querySelector('code');
      // If no code element (unlikely), fallback to block text
      const text = code ? code.innerText : block.innerText;

      navigator.clipboard.writeText(text).then(function() {
        button.innerText = 'Copied!';
        setTimeout(function() {
          button.innerText = 'Copy';
        }, 2000);
      }, function(err) {
        console.error('Could not copy text: ', err);
        button.innerText = 'Error';
      });
    });

    block.appendChild(button);
  });
});
