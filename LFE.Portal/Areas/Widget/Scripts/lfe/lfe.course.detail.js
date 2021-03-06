﻿var CHAPTER_CONTAINER_SELECTOR = "#d-chapter-content-container";
var BTN_CHPTER_TOGGL_PREFIX = 'btn-ch-toggle-';
var BTN_SELECT_VIDEO_PREFIX = 'btn-vd-select-';
var CHAPTER_UL_PREFIX = 'ul-v-';
var VIDE_NAME_PREFIX = 'lbl-video-name-';
var VIDEO_DESC_CONTAINER_PREFIX = 'spn-vd-des-';
var VIDEO_TITLE_SELECTOR = '#lbl-video-title';
var VIDEO_DESC_SELECTOR = '.ch-desc';
var CURRENT_VIDEO_TOKEN;
var VIDEO_NAV_ARRAY;
var isChapterLinksBound = false;

var tabsHashPrefix = {
    CONTENT: "content"
    , LEARNER: "learner"
    , DISCUSS: "discuss"
};

//#region learner
function onLearnersBound(e) {
    $.each(e.sender.wrapper.find('li'), function () {
        var li = $(this);
        li.unbind("click").bind('click', function () {
            window.showLearner(parseInt(li.attr('data-val')));
        });
    });
}

function onSortFiltersBound(e) {
    var listView = e.sender;

    var notifyEvent = notifEvents.report.sortCourse;

    $.each(listView.element.children().find('a'), function (i) {
        var token = listView.dataSource._data[i];
        var link = $(this);
        link.unbind('click');
        link.bind('click', function () {
            listView.element.children().find('a').removeClass('active');
            $(this).addClass('active');
            var filter = { field: token.field, dir: token.dir };
            window.getNotifManagerInstance().notify(notifyEvent, filter);
        });
        if (i == 0) link.addClass('active');
    });
}

function onCourseListBound() {
    window.getNotifManagerInstance().unsubscribe(notifEvents.report.sortCourse, sortCourseList, null);
    window.getNotifManagerInstance().subscribe(notifEvents.report.sortCourse, sortCourseList, null);
}

function sortCourseList(filter) {
    $('#LearnerCourses').data("kendoListView").dataSource.sort(filter);
}
//#endregion

function parseHash() {
    var hash = window.location.hash ? window.location.hash.substring(1) : null;
    if (hash == null) return [tabsHashPrefix.CONTENT];

    return hash.split('-');
}

function onCoursePageLoad(lastVideoId) {
    var hash = parseHash();//window.location.hash ? window.location.hash.substring(1) : null;
    if (lastVideoId < 0) {
        if (hash.length > 1) {
            if (hash.length == 3) {
                var video = findVideo(hash[2]);
                CURRENT_VIDEO_TOKEN = video != null ? video : VIDEO_NAV_ARRAY[0];
            } else {
                CURRENT_VIDEO_TOKEN = VIDEO_NAV_ARRAY[0];
            }
        } else {
            CURRENT_VIDEO_TOKEN = VIDEO_NAV_ARRAY[0];
        }
    } else {
        video = findVideo(lastVideoId);
        CURRENT_VIDEO_TOKEN = video != null ? video : VIDEO_NAV_ARRAY[0];
    }

    if (CURRENT_VIDEO_TOKEN == null) return;
    //set hash
    window.location.hash = hash[0] + '-' + CURRENT_VIDEO_TOKEN.chapterId + '-' + CURRENT_VIDEO_TOKEN.videoId;
    //toggle chapter
    $('#' + BTN_CHPTER_TOGGL_PREFIX + CURRENT_VIDEO_TOKEN.chapterId).click();
    //select video
    $('#' + BTN_SELECT_VIDEO_PREFIX + CURRENT_VIDEO_TOKEN.videoId).click();
}

function findVideo(id) {
    var json = VIDEO_NAV_ARRAY;
    if (json.length == 0) return null;

    for (var i = 0; i < json.length; i++) {
        if (json[i].videoId == id) return json[i];
    }

    return null;
}

function selectVideo(chapterId,videoId, $this) {
    //reset selection
    $('.li-video').removeClass('selected');
    ($($this).parent().parent()).addClass('selected'); //li

    //expand chapter if necessary
    var ul = $('#' + CHAPTER_UL_PREFIX + chapterId);
    var toBeOpen = ul.is(":hidden");
    if (toBeOpen) {
        $('#' + BTN_CHPTER_TOGGL_PREFIX + chapterId).click();
    }
    
    window.getNotifManagerInstance().notify(notifEvents.video.videoSelected, videoId);
}

function onVideoSelected(videoId) {
    var video = findVideo(videoId);

    if (video == null) {
        alert('video not found');
        return;
    }

    loadVideoData(video);
}

function loadVideoData(video) {

    var isChapterChanged = !isChapterLinksBound || window.CURRENT_VIDEO_TOKEN == null || window.CURRENT_VIDEO_TOKEN.chapterId != video.chapterId;

    window.CURRENT_VIDEO_TOKEN = video;

    if (isChapterChanged) {
        isChapterLinksBound = true;
        window.getNotifManagerInstance().notify(notifEvents.chapter.chapterChanged, window.CURRENT_VIDEO_TOKEN.chapterId);
    }

    var h = parseHash();

    window.location.hash = h[0] + '-' + CURRENT_VIDEO_TOKEN.chapterId + '-' + CURRENT_VIDEO_TOKEN.videoId;
    
    window.getNotifManagerInstance().notify(notifEvents.video.videoChanged, video);
    window.getNotifManagerInstance().notify(notifEvents.course.saveState, video);
    setVideoContent(video);

}

function setVideoContent(video) {
    window.getBcPlayerInstance().loadVideo(video);

    var name = $('#' + VIDE_NAME_PREFIX + video.videoId).html();
    var desc = $('#' + VIDEO_DESC_CONTAINER_PREFIX + video.videoId).html();

    $(VIDEO_TITLE_SELECTOR).fadeOut("slow", function () {
        $(VIDEO_TITLE_SELECTOR).html(name).fadeIn("slow");
    });

    $(VIDEO_DESC_SELECTOR).fadeOut("slow", function () {
        $(VIDEO_DESC_SELECTOR).html(desc).fadeIn("slow");
    });
}

function setNavButtonsState(video) {
    var nextId = video.nextId;
    var prevId = video.prevId;

    var btnPrev = $('#d-player-nav > .prev');
    var btnNext = $('#d-player-nav > .next');

    btnPrev.attr('data-val', prevId);
    btnNext.attr('data-val', nextId);

    if (nextId < 0) {
        btnNext.addClass('off');
    } else {
        btnNext.removeClass('off');
    }
    if (prevId < 0) {
        btnPrev.addClass('off');
    } else {
        btnPrev.removeClass('off');
    }
}
function onNavButtonClicked(direction,$this) {
    var btn = $($this);
    var targetVideoId = Number(btn.attr('data-val'));
    if (targetVideoId < 0) return;
    $('#' + BTN_SELECT_VIDEO_PREFIX + targetVideoId).click();
}

function setAutoplay() {
    var btn = $('#btn-autoplay');
    var isAutoplay = btn.hasClass('off');

    if (isAutoplay) {
        btn.removeClass('off').addClass('on').html('on');
    } else {
        btn.removeClass('on').addClass('off').html('off');
    }

   // window.getBcPlayerInstance().isAutoPlay = isAutoplay;
}
//#region tree events
function fixDescriptionH() {
    $.each($('.ul-chapters-tree').find('.txt'), function(i) {
        var span = $(this);
        // var label = $(span.find('label'));
        var text = span.html();
        var t = $(span.clone(true))
            .hide()
            .css({ 'position': 'absolute' })
            .width(span.width())
            .height('auto')
            .html(text);

        $('.ul-chapters-tree').append(t);

        var th = t.height();

        if (th > 75) {
            span.parent().append($('<span />').addClass('over').html('...'));
        }
        t.remove();
    });
}

function togglChapter(id,$this,factor) {
    var v = $('#ul-v-' + id);

    var t = factor == 1 ? $($this).parent().parent() : $($this).parent();
    var toBeOpen = v.is(":hidden");
    
    v.slideToggle("slow", function () {
        if (toBeOpen) {
            t.addClass('no-bord');
        } else {
            t.removeClass('no-bord');
        }
    });

    if (toBeOpen) {        
        t.find('.l-icon').removeClass('l-plus').addClass('l-minus');
    } else {
        t.find('.l-icon').addClass('l-plus').removeClass('l-minus');
    }
   

}

function togglVideo(id, $this) {
    var v = $('#vd-desc-' + id);

    var t = $($this).parent().parent();
    var toBeOpen = v.is(":hidden");

    if (toBeOpen) {
        t.find('.l-icon').removeClass('l-plus').addClass('l-minus');
    } else {
        t.find('.l-icon').addClass('l-plus').removeClass('l-minus');
    }
    v.slideToggle("slow", function() {
       
    });       
}



function expandCollapse(t) {

    $.each($('.ul-chapters-tree').find('.l-icon'),function() {
        var btn = $(this);
        var p = btn.parent().parent();
        var exp = p.siblings('.expandable');
        var isHidden = exp.is(":hidden");
        
        if (t == 1) {
            if(isHidden) btn.click();
        } else {
            if (!isHidden) btn.click();
        }
    });
}
//#endregion tree events

//#region player services
//function addPlayer() {

//    if (isPlayerAdded == false) {
//        isPlayerAdded = true;

//        var params = {};
//        params.playerID = "18731190001";
//        params.videoId = "1375772128";
//        //params.autoStart = "true";
//        params.bgcolor = "#993300";
//        params.width = "316";
//        params.height = "267";
//        params.isVid = "true";

//        var player = brightcove.createElement("object");
//        player.id = playerName;
//        var parameter;
//        for (var i in params) {
//            parameter = brightcove.createElement("param");
//            parameter.name = i;
//            parameter.value = params[i];
//            player.appendChild(parameter);
//        }

//        var playerContainer = document.getElementById("placeHolder");

//        brightcove.createExperience(player, playerContainer, true);
//    }
//}

//function removePlayer() {

//    if (isPlayerAdded == true) {
//        isPlayerAdded = false;

//        brightcove.removeExperience(playerName);
//    }

//}
//#endregion