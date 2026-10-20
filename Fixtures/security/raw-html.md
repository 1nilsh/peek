# Raw HTML

Expected with "Clean up": no Apple logo below (a dashed placeholder instead), the box reads
"script did not run", and the script's code appears as plain text.
Expected with "Show as text": all HTML below is shown literally.

Raw remote image: <img src="https://www.apple.com/favicon.ico" width="32">

<details><summary>Allowed markup (should be collapsible)</summary>
<p align="center">Centered paragraph</p>
</details>

<pre id="out">script did not run</pre>

<script>
var out = document.getElementById('out');
out.textContent = 'SCRIPT RAN: ' + location.href + ' / CSP meta: ' +
  (document.querySelector('meta[http-equiv="Content-Security-Policy"]') ? 'present' : 'missing');
fetch('https://example.com/', { mode: 'no-cors' })
  .then(function () { out.textContent += ' / network: REACHABLE'; })
  .catch(function (e) { out.textContent += ' / network: blocked'; });
</script>
