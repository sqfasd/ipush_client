
cordova.define("com.liveaa.xuexibao.MDMallPlugin", function(require, exports, module) { var exec = require('cordova/exec');
/**
 * Constructor
 */
               function MDMallPlugin() {}
/*                    */

               MDMallPlugin.prototype.sayHello = function() {
               exec(function(result){
                    // result handler
                    alert(result['body']);
                    // alert(result);
                    },
                    function(error){
                    // error handler
                    alert("Error" + error);
                    },
                    "MDMallPlugin",
                    "sayHello",
                    []
                    );
               }
               
               // v1.4接口：获取登录有效
               MDMallPlugin.prototype.getAuthData = function() {
                    exec(function(result) {
                         // result handler
                         UserData.user_agent = result['user_agent'];
                         UserData.token = escape(result['token']);
                         UserData.cookie = escape(result['cookie']);
                         UserData.mobile = escape(result['mobile']);
                         },
                         function(error){
                         // error handler
                         alert("Error" + error);
                         },
                         "MDMallPlugin",
                         "getAuthData",
                         []
                         );
               }
               
               MDMallPlugin.prototype.setTitle = function() {
               exec(function(result) {
                        alert("setTitle returned");
                    },
                    function(error) {
                        alert("setTitle error");
                    },
                    "MDMallPlugin",
                    "setTitle",
                    [document.title]//写入title的值
                    );
               }
               
               MDMallPlugin.prototype.inviteFriend = function() {
               exec(function(result) {
                        alert("inviteFriend returned");
                    },
                    function(error) {
                        alert("inviteFriend error");
                    },
                    "MDMallPlugin",
                    "inviteFriend",
                    []
                    );
               }

               MDMallPlugin.prototype.reportReqFail = function() {
               exec(function(result) {
                    
                    },
                    function(error) {
                    
                    },
                    "MDMallPlugin",
                    "reportReqFail",
                    []
                    );
               }
               
               MDMallPlugin.prototype.sendVerifiCode = function(tel) {
               exec(function(result) {
                    // 更改按钮状态
                    },
                    function(error) {
                        alert("inviteFriend error");
                    },
                    "MDMallPlugin",
                    "sendVerifiCode",
                    [tel]
                    );
               }
               
               
               var mallPlugin = new MDMallPlugin();
               module.exports = mallPlugin
               });

