cordova.define('cordova/plugin_list', function(require, exports, module) {
module.exports = [
               {
                  "file": "plugins/MDQuestionPlugin.js",
                  "id": "com.liveaa.xuexibao.MDQuestionPlugin",
                  "clobbers": [
                               "myPlugin"
                               ]
               },
               {
                  "file": "plugins/MDMallPlugin.js",
                  "id": "com.liveaa.xuexibao.MDMallPlugin",
                  "clobbers": [
                               "mallPlugin"
                               ]
               }
               ];
module.exports.metadata = 
// TOP OF METADATA
{
"com.liveaa.xuexibao.MDQuestionPlugin": "0.1.0",
"com.liveaa.xuexibao.MDMallPlugin": "0.1.0"
}
// BOTTOM OF METADATA
});
