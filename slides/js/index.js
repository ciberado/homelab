function cover() {
    const coverImage = document.createElement('img');
    coverImage.src = 'images/99.jpg';
    coverImage.addEventListener('load', function() {
      const canvases=[...document.querySelectorAll('.translucent canvas')];
      for (c of canvases) {
        const ctx = c.getContext("2d");
        ctx.globalCompositeOperation = ""; 
        ctx.drawImage(coverImage, 0, 0, 1920, 1080); 
      }
    });
}


this.setTimeout(cover, 2000);