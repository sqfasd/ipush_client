
var Active = {
	my_scroll:"",
	photo_height:20,
	y:0
};
function loadScroll() {
	var doc = document;
	doc.addEventListener('touchmove', function(e) { e.preventDefault(); }, false);
	if(Active.my_scroll !== "") {
		Active.my_scroll.refresh();
		if(Active.y < 0) {
			doc.getElementById("NavDiv").setAttribute("style","display:none;");
			Active.my_scroll.scrollTo(0, Active.y);
		}
	} else {
		Active.my_scroll = new IScroll('#IScroll', { probeType:3,mouseWheel:true,});
	}
	if(Results.img.length > 0 && doc.getElementById("Photo").title.length === 0) {
		doc.getElementById("Photo").innerHTML = Results.img;
		doc.getElementById("Photo").setAttribute("title","load");
	} else if(Results.img.length === 0 && doc.getElementById("Photo").title.length === 0) {
		doc.getElementById("Photo").innerHTML = '<img src="images/photo.png">';
		doc.getElementById("Photo").setAttribute("title","fail");
	}
	if(Results.r[Results.index].fold === true) {
		doc.getElementById("fold").setAttribute("src","images/unfold.png");
		doc.getElementById("fold").setAttribute("onclick","unfoldQuestion();");
		doc.getElementById("question").setAttribute("title","fold");
	} else {
		doc.getElementById("fold").setAttribute("src","images/fold.png");
		doc.getElementById("fold").setAttribute("onclick","foldQuestion();");
		doc.getElementById("question").setAttribute("title","unfold");
	}
	Active.my_scroll.on('scroll', updatePos);
	freshScroll();
}
function freshScroll() {
	var doc = document;
	var imgs = doc.getElementsByTagName("img");
	var min_h = 20;
	var max_h = 210;
	if(doc.getElementById("Photo").getElementsByTagName("img")[0].complete === true && imgs[imgs.length-1].complete === true) {
		if(doc.getElementById("Photo").title !== "complete") {
			doc.getElementById("Photo").setAttribute("title","complete");
			getImgdata();
			Active.photo_height = Math.min(doc.getElementById("Photo").offsetHeight,max_h);
			Active.photo_height = Math.max(Active.photo_height,min_h);
			doc.getElementById("PhotoFrame").setAttribute("style","height:"+(Active.photo_height+10)+"px;");
		}
		if(Results.status !== -1) {
			Active.my_scroll.refresh();
		}
	} else {
		setTimeout("freshScroll();",100);
	}
}
function updatePos() {
	var doc = document;
	if(Active.my_scroll.y<-Active.photo_height-42) {
		doc.getElementById("NavDiv").setAttribute("style","display:block;");
	} else {
		doc.getElementById("NavDiv").setAttribute("style","display:none;");
	}
}

function unfoldQuestion() {
	var doc = document;
	doc.getElementById("fold").setAttribute("src","images/fold.png");
	doc.getElementById("fold").setAttribute("onclick","foldQuestion();");
	doc.getElementById("question").setAttribute("title","unfold");
	Results.r[Results.index].fold = false;
	Active.my_scroll.refresh();
}
function foldQuestion() {
	var doc = document;
	doc.getElementById("fold").setAttribute("src","images/unfold.png");
	doc.getElementById("fold").setAttribute("onclick","unfoldQuestion();");
	doc.getElementById("question").setAttribute("title","fold");
	Results.r[Results.index].fold = true;
	Active.my_scroll.refresh();
	if(Active.my_scroll.y>=-Active.photo_height-42) {
		doc.getElementById("NavDiv").setAttribute("style","display:none;");
	}
}
function alertAnalog(str,fun,veri) {
    var doc = document;
    if(doc.getElementById("alertDiv")) {
        return;
    } else {
        var divOut = doc.createElement("div");
        divOut.id = "alertBack";
        var divIn = doc.createElement("div");
        divIn.id = "alertDiv";
        divIn.innerHTML = '<div id="alertContent"></div><div id="alert_yes">确定</div>';
        doc.getElementsByTagName("body")[0].appendChild(divOut);
        doc.getElementsByTagName("body")[0].appendChild(divIn);
        doc.getElementById("alertContent").innerHTML = str;
        if(str === veri) {
            doc.getElementById("alert_yes").setAttribute("onclick",fun);
        } else {
            doc.getElementById("alert_yes").setAttribute("onclick","closeAlert();");
        }
        doc.getElementById("alertBack").setAttribute("style","display:block;");
        doc.getElementById("alertDiv").setAttribute("style","display:block;");
    }
}
function confirmAnalog(str,fun,ret) {
    var doc = document;
    if(doc.getElementById("alertDiv")) {
        return;
    } else {
        var divOut = doc.createElement("div");
        divOut.id = "alertBack";
        var divIn = doc.createElement("div");
        divIn.id = "alertDiv";
        divIn.innerHTML = '<div id="alertContent"></div><div class="confirm-div"><div id="confirm_no">取消</div><div id="confirm_yes">确定</div></div>';
        doc.getElementsByTagName("body")[0].appendChild(divOut);
        doc.getElementsByTagName("body")[0].appendChild(divIn);
        doc.getElementById("alertContent").innerHTML = str;
        doc.getElementById("confirm_yes").setAttribute("onclick",fun);
        doc.getElementById("confirm_no").setAttribute("onclick",ret);
        doc.getElementById("alertBack").setAttribute("style","display:block;");
        doc.getElementById("alertDiv").setAttribute("style","display:block;");        
    }
}
function closeAlert() {
    var doc = document;
    var divout = doc.getElementById("alertBack");
    var divin = doc.getElementById("alertDiv");
    divout.parentNode.removeChild(divout);
    divin.parentNode.removeChild(divin);
}