<div id="deprecation-banner"
     style="
            position: relative;
            z-index: 999;
            top: 0;
            left: 0;
            right: 0;
            background: #fde073;
            text-align: center;
            line-height: 2.5;
            overflow: hidden;
            display: none;
            box-shadow:         0 0 5px black;
            "
>
    Ganglia is deprecated in favour of <a href="https://grafana.wikimedia.org">Grafana</a>.
    <a id="deprecation-close">[close]</a>
</div>

<script>
if ($.cookie("ganglia-deprecation") !== "ack") {
   $('#deprecation-banner').show();
}

$('#deprecation-close').on('click', function(){
   // Nag users again after 14 days.
   $.cookie("ganglia-deprecation", "ack", { expires : 14 });
   $('#deprecation-banner').hide();
})
</script>
