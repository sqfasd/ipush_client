// 数据初始化
var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicity call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        myPlugin.showLoading();
        myPlugin.showQuestion();
    },
};
    
window.onload =function() {
    FastClick.attach(document.body);
    app.initialize();
};
function jumpWaitting(result) {
    var doc = document;
    jiexi.innerHTML = '<div class="qy-ti_jiexinr2"><img class="waitting" id="waitting" src=""><span id="WaitRemind" class="waitting-remind"><\/span><div class="abnormal-btns" id="abnormal"><\/div><\/div>';
    jiexi.setAttribute("title","");
    waitting = doc.getElementById("waitting");
    waitremind = doc.getElementById("WaitRemind");
    abnormal = doc.getElementById("abnormal");
    waitting.setAttribute("src", "images/loading.png");
    waitremind.setAttribute("style","display:none;");
    abnormal.setAttribute("style","display:none;");
    remindWaitting(result);
}
function remindWaitting(result) {
    var doc = document;
    var status=result.status;
    Results.status = result.status;
    ResultsNav.setAttribute("style", "display:none;");
    if (status === 0) {
        Results.loading = setTimeout('remindWaitting();',60);
        waitting.setAttribute("style", "-webkit-transform:rotate("+20*(Results.loading%18)+"deg);");
    } else if (status === 2) {
        initResults(result);
    } else if (status === 1) {
        initResults(result);
    } else if (status === -1) {
        initResults(result);
    } else if (status === -2) {
        myPlugin.resultTitle(0);
        doc.getElementsByTagName("body")[0].setAttribute("title","err");
        doc.getElementById("result_remind").setAttribute("style","display:none;");
        waitting.setAttribute("style","display:none;");
        abnormal.setAttribute("style","display:none;");
        waitremind.innerHTML = "网络不给力，请稍后重试";
        waitremind.setAttribute("style","display:block;");
    }
}
function getImgdata() {
    var doc = document;
    var img = doc.getElementById("Photo").getElementsByTagName("img")[0];
    var img_src = img.src;
    var data_img = doc.getElementById("data_img");
    data_img.setAttribute("src",img_src);
    // data_img.onload = function() {
        var canvas = doc.getElementById("data_canvas");
        canvas.width = data_img.width;
        canvas.height = data_img.height;
        var ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0,0,data_img.width,data_img.height);
        var dataURL = canvas.toDataURL("image/jpg");
        var img_data = dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
        myPlugin.cacheImg(img_data);
    // }
}

// document.addEventListener("pause", function() {
//     pauseAudio();
// }, false);
