LoginForm = function() {
    var e = null,
        t = null,
        n = null;
    function a() {
        e = document.getElementById("login_form"), t = document.getElementById("f_user"), n = document.getElementById("f_pass"), setTimeout(function() {
            var e = document.getElementsByTagName("body");
            console.log(e), e.length && (e[0].style.visibility = "visible")
        }, 500), e.length > 0 && (function() {
            var e = t.parentNode.previousSibling,
                a = n.parentNode.previousSibling;
            e && (t.placeholder = e.textContent.length ? e.textContent : "User");
            a && (n.placeholder = a.textContent.length ? a.textContent : "Password")
        }(), function() {
            var e = document.getElementById("error_message");
            e && n.parentNode && n.parentNode.appendChild(e)
        }())
    }
    return window.onload = function() {
        a()
    }, this
}(), function(e, t) {
    "function" == typeof define && define.amd ? define([], t) : "object" == typeof module && module.exports ? module.exports = t() : e.EQCSS = t()
}(this, function() {
    var EQCSS = {
        data: [],
        version: "1.7.3"
    };
    EQCSS.load = function() {
        for (var e = document.getElementsByTagName("style"), t = 0; t < e.length; t++)
            "http://www.w3.org/2000/svg" !== e[t].namespaceURI && null === e[t].getAttribute("data-eqcss-read") && (e[t].setAttribute("data-eqcss-read", "true"), EQCSS.process(e[t].innerHTML));
        var n = document.getElementsByTagName("script");
        for (t = 0; t < n.length; t++)
            null === n[t].getAttribute("data-eqcss-read") && "text/eqcss" === n[t].type && (n[t].src ? function() {
                var e = new XMLHttpRequest;
                e.open("GET", n[t].src, !0), e.send(null), e.onreadystatechange = function() {
                    EQCSS.process(e.responseText)
                }
            }() : EQCSS.process(n[t].innerHTML), n[t].setAttribute("data-eqcss-read", "true"));
        var a = document.getElementsByTagName("link");
        for (t = 0; t < a.length; t++)
            null === a[t].getAttribute("data-eqcss-read") && "stylesheet" === a[t].rel && (a[t].href && function() {
                var e = new XMLHttpRequest;
                e.open("GET", a[t].href, !0), e.send(null), e.onreadystatechange = function() {
                    EQCSS.process(e.responseText)
                }
            }(), a[t].setAttribute("data-eqcss-read", "true"))
    }, EQCSS.parse = function(e) {
        var t = new Array;
        return (e = (e = (e = (e = (e = e || "").replace(/\s+/g, " ")).replace(/\/\*[\w\W]*?\*\//g, "")).replace(/@element/g, "\n@element")).replace(/(@element.*?\{([^}]*?\{[^}]*?\}[^}]*?)*\}).*/g, "$1")).replace(/(@element.*(?!@element))/g, function(e, n) {
            var a = {};
            n.replace(/(@element)\s*(".*?"|'.*?'|.*?)\s*(and\s*\(|{)/g, function(e, t, n) {
                n = (n = n.replace(/^\s?['](.*)[']/, "$1")).replace(/^\s?["](.*)["]/, "$1"), a.selector = n
            }), a.conditions = [], n.replace(/and ?\( ?([^:]*) ?: ?([^)]*) ?\)/g, function(e, t, n) {
                var o = null;
                (o = n.replace(/^(\d*\.?\d+)(\D+)$/, "$2")) === n && (o = null), n = n.replace(/^(\d*\.?\d+)\D+$/, "$1"), a.conditions.push({
                    measure: t,
                    value: n,
                    unit: o
                })
            }), n.replace(/{(.*)}/g, function(e, t) {
                a.style = t
            }), t.push(a)
        }), t
    }, EQCSS.register = function(e) {
        if ("[object Object]" === Object.prototype.toString.call(e) && (EQCSS.data.push(e), EQCSS.apply()), "[object Array]" === Object.prototype.toString.call(e)) {
            for (var t = 0; t < e.length; t++)
                EQCSS.data.push(e[t]);
            EQCSS.apply()
        }
    }, EQCSS.process = function(e) {
        var t = EQCSS.parse(e);
        return EQCSS.register(t)
    }, EQCSS.apply = function() {
        var e,
            t,
            n,
            a,
            o,
            r,
            i,
            d,
            l,
            s,
            c,
            u,
            S,
            p,
            h,
            m;
        for (e = 0; e < EQCSS.data.length; e++)
            for (a = document.querySelectorAll(EQCSS.data[e].selector), t = 0; t < a.length; t++) {
                o = "data-eqcss-" + e + "-" + t, a[t].setAttribute(o, ""), i = "data-eqcss-" + e + "-" + t + "-parent", a[t] != document.documentElement && a[t].parentNode.setAttribute(i, ""), d = "data-eqcss-" + e + "-" + t + "-prev";
                var f = function(e) {
                    for (; e = e.previousSibling;)
                        if (1 === e.nodeType)
                            return e
                }(a[t]);
                f && f.setAttribute(d, ""), l = "data-eqcss-" + e + "-" + t + "-next";
                var E = function(e) {
                    for (; e = e.nextSibling;)
                        if (1 === e.nodeType)
                            return e
                }(a[t]);
                E && E.setAttribute(l, ""), (r = document.querySelector("#" + o)) || ((r = document.createElement("style")).id = o, r.setAttribute("data-eqcss-read", "true"), document.querySelector("head").appendChild(r)), r = document.querySelector("#" + o), p = !0;
                e:
                for (n = 0; n < EQCSS.data[e].conditions.length; n++) {
                    h = window.getComputedStyle(a[t], null), m = null, a[t] != document.documentElement && (m = window.getComputedStyle(a[t].parentNode, null));
                    var g,
                        C = !1;
                    if ("vw" === EQCSS.data[e].conditions[n].unit)
                        C = !0, g = parseInt(EQCSS.data[e].conditions[n].value), EQCSS.data[e].conditions[n].recomputed_value = g * window.innerWidth / 100;
                    else if ("vh" === EQCSS.data[e].conditions[n].unit)
                        C = !0, g = parseInt(EQCSS.data[e].conditions[n].value), EQCSS.data[e].conditions[n].recomputed_value = g * window.innerHeight / 100;
                    else if ("vmin" === EQCSS.data[e].conditions[n].unit)
                        C = !0, g = parseInt(EQCSS.data[e].conditions[n].value), EQCSS.data[e].conditions[n].recomputed_value = g * Math.min(window.innerWidth, window.innerHeight) / 100;
                    else if ("vmax" === EQCSS.data[e].conditions[n].unit)
                        C = !0, g = parseInt(EQCSS.data[e].conditions[n].value), EQCSS.data[e].conditions[n].recomputed_value = g * Math.max(window.innerWidth, window.innerHeight) / 100;
                    else if (null != EQCSS.data[e].conditions[n].unit && "px" != EQCSS.data[e].conditions[n].unit && "%" != EQCSS.data[e].conditions[n].unit) {
                        var y = document.createElement("div");
                        y.style.visibility = "hidden", y.style.border = "1px solid red", y.style.width = EQCSS.data[e].conditions[n].value + EQCSS.data[e].conditions[n].unit;
                        var Q = a[t];
                        a[t] != document.documentElement && (Q = a[t].parentNode), Q.appendChild(y), EQCSS.data[e].conditions[n].value = parseInt(window.getComputedStyle(y, null).getPropertyValue("width")), EQCSS.data[e].conditions[n].unit = "px", Q.removeChild(y)
                    }
                    var v = C ? EQCSS.data[e].conditions[n].recomputed_value : parseInt(EQCSS.data[e].conditions[n].value);
                    switch (EQCSS.data[e].conditions[n].measure) {
                    case "min-width":
                        if (!(!0 !== C && "px" !== EQCSS.data[e].conditions[n].unit || (c = parseInt(h.getPropertyValue("width"))) >= v)) {
                            p = !1;
                            break e
                        }
                        if ("%" === EQCSS.data[e].conditions[n].unit && (c = parseInt(h.getPropertyValue("width")), !(parseInt(m.getPropertyValue("width")) / c <= 100 / v))) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-width":
                        if (!(!0 !== C && "px" !== EQCSS.data[e].conditions[n].unit || (c = parseInt(h.getPropertyValue("width"))) <= v)) {
                            p = !1;
                            break e
                        }
                        if ("%" === EQCSS.data[e].conditions[n].unit && (c = parseInt(h.getPropertyValue("width")), !(parseInt(m.getPropertyValue("width")) / c >= 100 / v))) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-height":
                        if (!(!0 !== C && "px" !== EQCSS.data[e].conditions[n].unit || (u = parseInt(h.getPropertyValue("height"))) >= v)) {
                            p = !1;
                            break e
                        }
                        if ("%" === EQCSS.data[e].conditions[n].unit && (u = parseInt(h.getPropertyValue("height")), !(parseInt(m.getPropertyValue("height")) / u <= 100 / v))) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-height":
                        if (!(!0 !== C && "px" !== EQCSS.data[e].conditions[n].unit || (u = parseInt(h.getPropertyValue("height"))) <= v)) {
                            p = !1;
                            break e
                        }
                        if ("%" === EQCSS.data[e].conditions[n].unit && (u = parseInt(h.getPropertyValue("height")), !(parseInt(m.getPropertyValue("height")) / u >= 100 / v))) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-scroll-x":
                        var w = a[t],
                            b = w.scrollLeft;
                        if (w.hasScrollListener || (w === document.documentElement || w === document.body ? window.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        }) : w.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        })), !0 === C || "px" === EQCSS.data[e].conditions[n].unit) {
                            if (!(b >= v)) {
                                p = !1;
                                break e
                            }
                        } else if ("%" === EQCSS.data[e].conditions[n].unit) {
                            var x = a[t].scrollWidth;
                            if (!(b / (x - (a[t] === document.documentElement || a[t] === document.body ? window.innerWidth : parseInt(h.getPropertyValue("width")))) * 100 >= v)) {
                                p = !1;
                                break e
                            }
                        }
                        break;
                    case "min-scroll-y":
                        if (w = a[t], b = a[t].scrollTop, w.hasScrollListener || (w === document.documentElement || w === document.body ? window.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        }) : w.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        })), !0 === C || "px" === EQCSS.data[e].conditions[n].unit) {
                            if (!(b >= v)) {
                                p = !1;
                                break e
                            }
                        } else if ("%" === EQCSS.data[e].conditions[n].unit && !(b / ((x = a[t].scrollHeight) - (a[t] === document.documentElement || a[t] === document.body ? window.innerHeight : parseInt(h.getPropertyValue("height")))) * 100 >= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-scroll-x":
                        if (w = a[t], b = a[t].scrollLeft, w.hasScrollListener || (w === document.documentElement || w === document.body ? window.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        }) : w.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        })), !0 === C || "px" === EQCSS.data[e].conditions[n].unit) {
                            if (!(b <= v)) {
                                p = !1;
                                break e
                            }
                        } else if ("%" === EQCSS.data[e].conditions[n].unit && !(b / ((x = a[t].scrollWidth) - (a[t] === document.documentElement || a[t] === document.body ? window.innerWidth : parseInt(h.getPropertyValue("width")))) * 100 <= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-scroll-y":
                        if (w = a[t], b = a[t].scrollTop, w.hasScrollListener || (w === document.documentElement || w === document.body ? window.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        }) : w.addEventListener("scroll", function() {
                            EQCSS.throttle(), w.hasScrollListener = !0
                        })), !0 === C || "px" === EQCSS.data[e].conditions[n].unit) {
                            if (!(b <= v)) {
                                p = !1;
                                break e
                            }
                        } else if ("%" === EQCSS.data[e].conditions[n].unit && !(b / ((x = a[t].scrollHeight) - (a[t] === document.documentElement || a[t] === document.body ? window.innerHeight : parseInt(h.getPropertyValue("height")))) * 100 <= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-characters":
                        if (a[t].value) {
                            if (!(a[t].value.length >= v)) {
                                p = !1;
                                break e
                            }
                        } else if (!(a[t].textContent.length >= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-characters":
                        if (a[t].value) {
                            if (!(a[t].value.length <= v)) {
                                p = !1;
                                break e
                            }
                        } else if (!(a[t].textContent.length <= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-children":
                        if (!(a[t].children.length >= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-children":
                        if (!(a[t].children.length <= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-lines":
                        if (u = parseInt(h.getPropertyValue("height")) - parseInt(h.getPropertyValue("border-top-width")) - parseInt(h.getPropertyValue("border-bottom-width")) - parseInt(h.getPropertyValue("padding-top")) - parseInt(h.getPropertyValue("padding-bottom")), "normal" === (S = h.getPropertyValue("line-height"))) {
                            var k = parseInt(h.getPropertyValue("font-size"));
                            S = 1.125 * k
                        } else
                            S = parseInt(S);
                        if (!(u / S >= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-lines":
                        if (!((u = parseInt(h.getPropertyValue("height")) - parseInt(h.getPropertyValue("border-top-width")) - parseInt(h.getPropertyValue("border-bottom-width")) - parseInt(h.getPropertyValue("padding-top")) - parseInt(h.getPropertyValue("padding-bottom"))) / (S = "normal" === (S = h.getPropertyValue("line-height")) ? 1.125 * (k = parseInt(h.getPropertyValue("font-size"))) : parseInt(S)) + 1 <= v)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "orientation":
                        if ("square" === EQCSS.data[e].conditions[n].value && a[t].offsetWidth !== a[t].offsetHeight) {
                            p = !1;
                            break e
                        }
                        if ("portrait" === EQCSS.data[e].conditions[n].value && !(a[t].offsetWidth < a[t].offsetHeight)) {
                            p = !1;
                            break e
                        }
                        if ("landscape" === EQCSS.data[e].conditions[n].value && !(a[t].offsetHeight < a[t].offsetWidth)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "min-aspect-ratio":
                        var I = EQCSS.data[e].conditions[n].value.split("/")[0],
                            _ = EQCSS.data[e].conditions[n].value.split("/")[1];
                        if (!(I / _ <= a[t].offsetWidth / a[t].offsetHeight)) {
                            p = !1;
                            break e
                        }
                        break;
                    case "max-aspect-ratio":
                        if (I = EQCSS.data[e].conditions[n].value.split("/")[0], _ = EQCSS.data[e].conditions[n].value.split("/")[1], !(a[t].offsetWidth / a[t].offsetHeight <= I / _)) {
                            p = !1;
                            break e
                        }
                    }
                }
                if (!0 === p) {
                    s = (s = (s = (s = (s = (s = (s = (s = EQCSS.data[e].style).replace(/eval\( *((".*?")|('.*?')) *\)/g, function(e, n) {
                        return EQCSS.tryWithEval(a[t], n)
                    })).replace(/(\$|eq_)this/gi, "[" + o + "]")).replace(/(\$|eq_)parent/gi, "[" + i + "]")).replace(/(\$|eq_)prev/gi, "[" + d + "]")).replace(/(\$|eq_)next/gi, "[" + l + "]")).replace(/(\$|eq_)root/gi, "html")).replace(/(\d*\.?\d+)(?:\s*)(ew|eh|emin|emax)/gi, function(e, n, o) {
                        switch (o) {
                        case "ew":
                            return a[t].offsetWidth / 100 * n + "px";
                        case "eh":
                            return a[t].offsetHeight / 100 * n + "px";
                        case "emin":
                            return Math.min(a[t].offsetWidth, a[t].offsetHeight) / 100 * n + "px";
                        case "emax":
                            return Math.max(a[t].offsetWidth, a[t].offsetHeight) / 100 * n + "px"
                        }
                    });
                    try {
                        r.innerHTML = s
                    } catch (e) {
                        r.styleSheet.cssText = s
                    }
                } else
                    try {
                        r.innerHTML = ""
                    } catch (e) {
                        r.styleSheet.cssText = ""
                    }
            }
    }, EQCSS.tryWithEval = function(element, string) {
        var $it = element,
            ret = "";
        try {
            with ($it)
                ret = eval(string.slice(1, -1))
        } catch (e) {
            ret = ""
        }
        return ret
    }, EQCSS.reset = function() {
        EQCSS.data = [];
        for (var e = document.querySelectorAll('head style[id^="data-eqcss-"]'), t = 0; t < e.length; t++)
            e[t].parentNode.removeChild(e[t]);
        for (var n = document.querySelectorAll("*"), a = 0; a < n.length; a++)
            for (var o = 0; o < n[a].attributes.length; o++)
                0 === n[a].attributes[o].name.indexOf("data-eqcss-") && n[a].removeAttribute(n[a].attributes[o].name)
    }, EQCSS.domReady = function(e) {
        var t = !1,
            n = !0,
            a = window.document,
            o = a.documentElement,
            r = !~navigator.userAgent.indexOf("MSIE 8"),
            i = r ? "addEventListener" : "attachEvent",
            d = r ? "removeEventListener" : "detachEvent",
            l = r ? "" : "on",
            s = function(n) {
                "readystatechange" === n.type && "complete" !== a.readyState || (("load" === n.type ? window : a)[d](l + n.type, s, !1), !t && (t = !0) && e.call(window, n.type || n))
            },
            c = function() {
                try {
                    o.doScroll("left")
                } catch (e) {
                    return void setTimeout(c, 50)
                }
                s("poll")
            };
        if ("complete" === a.readyState)
            e.call(window, "lazy");
        else {
            if (!r && o.doScroll) {
                try {
                    n = !window.frameElement
                } catch (e) {}
                n && c()
            }
            a[i](l + "DOMContentLoaded", s, !1), a[i](l + "readystatechange", s, !1), window[i](l + "load", s, !1)
        }
    };
    var EQCSS_throttle_available = !0,
        EQCSS_throttle_queued = !1,
        EQCSS_mouse_down = !1,
        EQCSS_timeout = 200;
    EQCSS.throttle = function() {
        EQCSS_throttle_available ? (EQCSS.apply(), EQCSS_throttle_available = !1, setTimeout(function() {
            EQCSS_throttle_available = !0, EQCSS_throttle_queued && (EQCSS_throttle_queued = !1, EQCSS.apply())
        }, EQCSS_timeout)) : EQCSS_throttle_queued = !0
    }, EQCSS.domReady(function() {
        EQCSS.load(), EQCSS.throttle()
    }), window.addEventListener("resize", EQCSS.throttle), window.addEventListener("input", EQCSS.throttle), window.addEventListener("click", EQCSS.throttle), window.addEventListener("mousedown", function(e) {
        1 === e.which && (EQCSS_mouse_down = !0)
    }), window.addEventListener("mousemove", function() {
        EQCSS_mouse_down && EQCSS.throttle()
    }), window.addEventListener("mouseup", function() {
        EQCSS_mouse_down = !1, EQCSS.throttle()
    });
    function l(e) {
        console.log(e)
    }
    return EQCSS
});
