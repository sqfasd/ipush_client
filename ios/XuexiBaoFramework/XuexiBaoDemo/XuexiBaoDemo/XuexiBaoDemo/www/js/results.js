
var jiexi = document.getElementById("Solution");
var SeekHelp = document.getElementById("SeekHelp");
var ResultsNav = document.getElementById("ResultsNav");
var waitting;
var waitremind;
var abnormal;
var Results = {
	status:0,
	index:0,
	is_ask:false,
	r:[],
	len:0,
};
function initResults(data) {
	var doc = document;
	if(Results.status > 0) {
		var array = data.machine_answers;
		Results.len = array.length;
		for(var i=0; i<Results.len; i++) {
			var newObj = new Object();
			newObj.body = array[i].body;
			newObj.fold = false;
			newObj.answer = array[i].answer;
			newObj.analysis = array[i].analysis;
			newObj.tags = array[i].tags;
			var subIndex = parseInt(array[i].subject.toString());
			var subs = ["未知","数学","语文","英语","政治","历史","地理","物理","化学","生物","众答"];
			newObj.kind = subs[subIndex];
            Results.r.push(newObj);
			newObj.questionId = array[i].questionId;
			newObj.image_id = array[i].image_id;
			doc.getElementsByClassName("result-fixed")[i].setAttribute("style","display:block;");
		}
		for(var j=Results.len; j<3; j++) {
			Results.r.push(null);
		}
		Results.is_ask = data.is_ask;
		if(typeof data.cache_index === "undefined") {
			Results.index = 0;
		} else {
			Results.index = Math.max(data.cache_index,0);
		}
		if(Results.status === 1) {
			myPlugin.resultTitle(1);
			doc.getElementById("result_remind").setAttribute("style","display:inline;");
			getCache();
			showResult(Results.index);
		} else if(Results.status === 2) {
			myPlugin.resultTitle(1);
			doc.getElementById("result_remind").setAttribute("style","display:inline;");
			getCache();
			showResult(Results.index);
		}
	} else if(Results.status === -1) {
		myPlugin.resultTitle(0);
		doc.getElementsByTagName("body")[0].setAttribute("title","err");
		if(Results.img.length > 0 && doc.getElementById("Photo").title.length === 0) {
			doc.getElementById("Photo").innerHTML = Results.img;
			doc.getElementById("Photo").setAttribute("title","load");
		} else if(Results.img.length === 0 && doc.getElementById("Photo").title.length === 0) {
			doc.getElementById("Photo").innerHTML = '<img src="images/photo.png">';
			doc.getElementById("Photo").setAttribute("title","fail");
		}
		freshScroll();
		Results.is_ask = data.is_ask;
		jiexi.innerHTML = "";
		doc.getElementById("HelpTitle").innerHTML = "没有找到答案";
		// showHelp();
	}
}
function showHelp() {
	var doc = document;
	if(Results.is_ask === true) {
		doc.getElementById("HelpTitle").innerHTML = "看看学霸怎么说…";
		doc.getElementById("StudentsHelp").innerHTML = "查看我的求助";
		doc.getElementById("StudentsHelp").setAttribute("onclick","myPlugin.showDiscus();");
	} else if(Results.is_ask === false && Results.len === 0) {
		doc.getElementById("HelpTitle").innerHTML = "没有找到答案";
		doc.getElementById("StudentsHelp").innerHTML = "求助学霸";
		doc.getElementById("StudentsHelp").setAttribute("onclick","myPlugin.seekHelp();");
	} else {
		doc.getElementById("HelpTitle").innerHTML = "答案不满意？";
		doc.getElementById("StudentsHelp").innerHTML = "求助学霸";
		doc.getElementById("StudentsHelp").setAttribute("onclick","myPlugin.seekHelp();");
	}
	SeekHelp.setAttribute("style","display:block;");
}
function hasHelp() {
	var doc = document;
	doc.getElementById("HelpTitle").innerHTML = "看看学霸怎么说…";
	doc.getElementById("StudentsHelp").innerHTML = "查看我的求助";
	doc.getElementById("StudentsHelp").setAttribute("onclick","myPlugin.showDiscus();");
	Results.is_ask = true;
}
function getResultOrder() {
	var doc = document;
	var Order = event.currentTarget;
	for(var i=0;i<Results.len;i++) {
		ResultsNav.getElementsByClassName("result")[i].title = "";
		doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[i].title = "";
	}
	Order.setAttribute("title", "current-result");
	for(var i=0;i<Results.len;i++) {
		if (ResultsNav.getElementsByClassName("result")[i].title === "current-result") {
			Results.index = i;
			myPlugin.cacheIndex();
		}
	}
	doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[Results.index].setAttribute("title","current-result");
	Active.y = Math.max(Active.my_scroll.y,-Active.photo_height-42);
	showResult(Results.index);
}
function getResultOrderFixed() {
	var doc = document;
	var Order = event.currentTarget;
	for(var i=0;i<Results.len;i++) {
		ResultsNav.getElementsByClassName("result")[i].title = "";
		doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[i].title = "";
	}
	Order.setAttribute("title", "current-result");
	for(var i=0;i<Results.len;i++) {
		if (doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[i].title === "current-result") {
			Results.index = i;
			myPlugin.cacheIndex();
		}
	}
	ResultsNav.getElementsByClassName("result")[Results.index].setAttribute("title","current-result");
	Active.y = Math.max(Active.my_scroll.y,-Active.photo_height-42);
	showResult(Results.index);
}
function showResult(ResultNum) {
	var doc = document;
	if(ResultsNav.style.display === "none") {
		ResultsNav.setAttribute("style","display:block;");
	}
	if(doc.getElementById("question")) {
	} else {
		jiexi.innerHTML = '<div id="QuestionSection" class="solve"><div class="info-bar"><img class="solve-h solve-h-question" src="images/q.png"><span class="subject-frame-l">[ </span><span id="Subject"></span><span class="subject-frame-r"> ]</span></div><div id="question" class="detail"></div><div class="fold"><img id="fold" src="images/fold.png" onclick="foldQuestion();"><br class="clear"></div></div><div id="AnswerSection" class="solve"><div class="info-bar"><img class="solve-h solve-h-answer" src="images/a.png"><span class="answer-title">解答</span></div><div id="answer" class="detail"></div><div id="analysis" class="detail"></div></div><div id="ThemeSection" class="solve"><span class="solve-h-theme">知识点</span><div id="theme" class="detail"></div></div>';
	}
	doc.getElementById("question").innerHTML = Results.r[ResultNum]['body'];
	var tags_str = Results.r[ResultNum]['tags'];
	if(tags_str.toString().length < 5 && (tags_str === "" || tags_str.toLowerCase() === "null")) {
		doc.getElementById("theme").innerHTML = "";
	} else {
		doc.getElementById("theme").innerHTML = tags_str;
	}
	var answer_str = Results.r[ResultNum]['answer'];
	var analysis_str = Results.r[ResultNum]['analysis'];
	if(answer_str.toString().length < 5 && (answer_str === "" || answer_str.toLowerCase() === "null")) {
		answer_str = "";
	}
	if(analysis_str.toString().length < 5 && (analysis_str === "" || analysis_str.toLowerCase() === "null")) {
		analysis_str = "";
	}
	doc.getElementById("answer").innerHTML = answer_str;
	doc.getElementById("analysis").innerHTML = analysis_str;
	if(typeof Results.r[ResultNum]['kind'] == "undefined") {
		doc.getElementById("Subject").innerHTML = "未知";
	} else {
		doc.getElementById("Subject").innerHTML = Results.r[ResultNum]['kind'];
	}
    setTimeout("loadScroll();",100);
}
function getCache() {
	var doc = document;
	for(var i=0;i<Results.len;i++) {
		doc.getElementById("ResultsNav").getElementsByClassName("result")[i].setAttribute("style","display:block;");
		ResultsNav.getElementsByClassName("result")[i].onclick = function() {
			getResultOrder();
		}
		doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[i].onclick = function() {
			getResultOrderFixed();
		}
	}
	ResultsNav.getElementsByClassName("result")[Results.index].title = "current-result";
	doc.getElementById("NavFixed").getElementsByClassName("result-fixed")[Results.index].title = "current-result";
	myPlugin.cacheIndex();
	// showHelp();
}