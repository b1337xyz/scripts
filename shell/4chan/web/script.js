counter_current = document.querySelector("#counter-current");
counter_total = document.querySelector("#counter-total");
vids = document.querySelectorAll("video");
allimgs = document.querySelectorAll("img");
slider = document.querySelector("#slider");
imgs = new Array();
gifs = new Array();
all = new Array();
slider.oninput = function() {
    for ( i = 0 ; i < vids.length ; i++ )
        vids[i].volume = this.value / 100
}
/*for ( i = 0 ; i < vids.length ; i++ ) {
    vids[i].addEventListener("focusout", function() {
        if ( ! this.paused )
            this.pause()
    });
}*/
for ( i = 0 ; i < allimgs.length ; i++ ) {
    if ( allimgs[i].src.match(/\.(png|jpg)$/) ) { 
        imgs.push(allimgs[i]);
    } else if ( allimgs[i].src.match(/\.gif$/) ) {
        gifs.push(allimgs[i]);
    }
    all.push(allimgs[i]);
}
for ( i = 0; i < vids.length; i++ )
    all.push(vids[i]);

counter_total.textContent = all.length;
function update_counter() {
    total = 0
    for ( i = 0; i < all.length; i++ ) {
        if (all[i].style.display != "none")
            total += 1
    }
    counter_total.textContent = total
}
for ( i = 0; i < all.length; i++ ) {
    all[i].onmouseover = function(e) {
        counter_current.textContent = all.indexOf(e.target) + 1;
    }
}

function unmute(el) {
    for ( i = 0 ; i < vids.length ; i++ )
        vids[i].muted = !(vids[i].muted);

    console.log(el)
    if ( el.textContent == "Unmute" ) {
        el.textContent = "Mute";
    } else {
        el.textContent = "Unmute";
    }
}
function showAll() {
    for ( i = 0 ; i < allimgs.length ; i++ )
        imgs[i].style.display = "inline-block"; 
    for ( i = 0 ; i < vids.length ; i++ )
        imgs[i].style.display = "inline-block"; 
    update_counter();
}
function onlyWide() {
    for ( i = 0 ; i < imgs.length ; i++ ) {
        if ( imgs[i].width <= imgs[i].height ) {
            imgs[i].style.display = "none";
        } else {
            imgs[i].style.display = "inline-block"; 
        }
    }
    update_counter();
}
function onlyTall() {
    for ( i = 0 ; i < imgs.length ; i++ ) {
        if ( imgs[i].width > imgs[i].height ) {
            imgs[i].style.display = "none";
        } else {
            imgs[i].style.display = "inline-block"; 
        }
    }
    update_counter();
}
function onlyVid() {
    if (vids.length > 0) {
        for ( i = 0 ; i < allimgs.length ; i++ )
            allimgs[i].style.display = "none"; 

        for ( i = 0; i < vids.length ; i++ )
            vids[i].style.display = "inline-block";

        update_counter();
    }
}
function onlyGif() {
    if (gifs.length > 0) {
        for ( i = 0 ; i < vids.length ; i++ )
            vids[i].style.display = "none";

        for ( i = 0 ; i < imgs.length ; i++ )
            imgs[i].style.display = "none";

        for ( i = 0 ; i < gifs.length ; i++ )
            gifs[i].style.display = "inline-block";

        update_counter();
    }
}
function onlyImg() {
    if (imgs.length > 0) {
        for ( i = 0 ; i < vids.length ; i++ )
            vids[i].style.display = "none";

        for ( i = 0 ; i < gifs.length ; i++ )
            gifs[i].style.display = "none";

        for ( i = 0 ; i < imgs.length ; i++ )
            imgs[i].style.display = "inline-block";

        update_counter();
    }
}
