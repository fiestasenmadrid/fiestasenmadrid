(function () {
  function norm(s) {
    return s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[^a-z0-9]+/g, ' ').trim();
  }

  // Si la actualización diaria fallase, oculta los días que ya han pasado
  // (hasta las 8:00 se mantiene la noche anterior, que sigue en marcha).
  var ahora = new Date();
  var ref = new Date(ahora.getTime() - (ahora.getHours() < 8 ? 864e5 : 0));
  var hoy = ref.getFullYear() + '-' + ('0' + (ref.getMonth() + 1)).slice(-2) + '-' + ('0' + ref.getDate()).slice(-2);
  document.querySelectorAll('[data-fecha]').forEach(function (el) {
    if (el.getAttribute('data-fecha') < hoy) el.remove();
  });

  var q = document.getElementById('buscar');
  var filtro = 'todo';

  function aplicar() {
    var t = q ? norm(q.value) : '';
    var total = 0;
    document.querySelectorAll('.dia').forEach(function (sec) {
      var vis = 0;
      sec.querySelectorAll('.card').forEach(function (c) {
        var ok = (!t || c.getAttribute('data-q').indexOf(t) > -1) &&
                 (filtro === 'todo' || c.getAttribute('data-tipo') === filtro);
        c.hidden = !ok;
        if (ok) vis++;
      });
      sec.hidden = !vis;
      total += vis;
    });
    var v = document.getElementById('vacio');
    if (v) v.hidden = total > 0;
  }

  // Aviso de fiesta destacada: aparece a los 6 s y, si se cierra, no vuelve en 24 h
  var promo = document.getElementById('promo');
  if (promo) {
    var clave = 'promo-' + promo.getAttribute('data-id');
    var visto = 0;
    try { visto = +localStorage.getItem(clave) || 0; } catch (e) {}
    var recordar = function () { try { localStorage.setItem(clave, String(Date.now())); } catch (e) {} };
    if (Date.now() - visto > 864e5) {
      setTimeout(function () {
        promo.hidden = false;
        requestAnimationFrame(function () { promo.classList.add('on'); });
      }, 6000);
    }
    promo.querySelector('.promo-x').addEventListener('click', function () {
      promo.classList.remove('on');
      setTimeout(function () { promo.hidden = true; }, 300);
      recordar();
    });
    promo.querySelectorAll('a').forEach(function (a) { a.addEventListener('click', recordar); });
  }

  if (q) q.addEventListener('input', aplicar);
  document.querySelectorAll('[data-f]').forEach(function (b) {
    b.addEventListener('click', function () {
      filtro = b.getAttribute('data-f');
      document.querySelectorAll('[data-f]').forEach(function (x) {
        x.classList.toggle('on', x === b);
        x.setAttribute('aria-pressed', x === b ? 'true' : 'false');
      });
      aplicar();
    });
  });
})();
