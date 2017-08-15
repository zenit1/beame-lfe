﻿
function updateWixSiteUrl() {
    Wix.getSiteInfo(function (siteInfo) {
        var wixSiteUrl = siteInfo.baseUrl;

        if (lfeWixSiteUrl == '') {
            $.ajax({
                'type': 'post',
                'contentType': 'application/json; charset=utf-8',
                'url': "/WixEndPoint/Home/UpdateWixStoreUrl",
                'data': '{"StoreId":"' + lfeStoreId + '","WixSiteUrl":"' + wixSiteUrl + '"}',
                'cache': false,
                'success': function (res) {
                    //console.log('site url updated');
                },
                'error': function (res) {
                    //console.log('error updating data to the app server');
                }
            });
        }

    });


}

var wixSiteUrl = '';
$(document).ready(function () {
    Wix.setHeight($(document).height());

    var viewMode = Wix.Utils.getViewMode();
    if (viewMode == 'editor' || viewMode == 'preview') {
        // CheckRefresh();
        $('a').addClass('disabled');
        $('a').click(function () {
            if ($(this).hasClass('disabled'))
                return false;
        });
    }


    updateWixSiteUrl();

    Wix.addEventListener(Wix.Events.COMPONENT_DELETED, function (data) {
        var url = wixLogAppDeletedUrl.replace("instanceId_PlaceHolder", Wix.Utils.getInstanceId()).replace("wixSiteUrl_PlaceHolder", wixSiteUrl)
        $.ajax({
            url: url
            , dataType: "json"
            , cache: false
            , success: function (response) { }
        });
    });
    Wix.addEventListener(Wix.Events.SITE_PUBLISHED, function (data) {
        var url = wixLogAppPublishUrl.replace("instanceId_PlaceHolder", Wix.Utils.getInstanceId()).replace("wixSiteUrl_PlaceHolder", wixSiteUrl)
        $.ajax({
            url: url
            , dataType: "json"
            , cache: false
            , success: function (response) { }
        });
    });



});

