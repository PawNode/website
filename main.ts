import { configOut } from "./config.js";
import { httpGet, IHTTPResult } from "./ethernet/ip/tcp/http/index.js";
import { addInterfaceEasy } from "./interface/util.js";
import { arrayToBase64 } from "./util/base64.js";
import { arrayToString } from "./util/string.js";
import { WSVPN } from "./wsvpn.js";

// tslint:disable:no-console

let iframe: HTMLIFrameElement;
let iframeDoc: Document;

type RequestCB = (ele: HTMLElement, res: IHTTPResult) => void;

interface IRequest {
    src: URL;
    ele: HTMLElement;
    func: RequestCB;
}

const requestQueue: IRequest[] = [];

const INITIAL_URL = new URL("http://jsip.local/");
let BASE_URL = INITIAL_URL;

function mkUrl(relative: string) {
    return new URL(relative, BASE_URL);
}

function requestQueueNext() {
    const req = requestQueue.pop();
    if (!req) {
        console.log("Page load completed!");
        return;
    }

    httpGet({ url: req.src, errorOnNon200: true }).then((res) => {
        setTimeout(requestQueueNext, 0);

        if (res.statusCode !== 200) {
            console.error("Status code", res.statusCode, "for URL", req.src);
            return;
        }

        console.log("Fetched data for", req.ele, "successfully");

        req.func(req.ele, res);
    }).catch((err) => {
        console.error("Error fetching", err);
        setTimeout(requestQueueNext, 0);
    });
}

function loadInnerTextFunc(ele: HTMLElement, res: IHTTPResult) {
    ele.innerHTML = arrayToString(res.body);
}

function loadImgFunc(ele: HTMLElement, res: IHTTPResult) {
    const contentType = res.headers.first("content-type");
    if (!contentType || !contentType.startsWith("image/")) {
        console.error("Invalid content-type", contentType, "for URL", res.url, "for element", ele);
        return;
    }
    (ele as HTMLImageElement).src = `data:${contentType};base64, ${arrayToBase64(res.body)}`;
}

function rewriteSubelements(elements: HTMLCollectionOf<HTMLElement>, attr: string) {
    // tslint:disable-next-line:prefer-for-of
    for (let i = 0; i < elements.length; i++) {
        const ele = elements[i];
        const oldAttr = ele.getAttribute(attr);
        if (oldAttr) {
            ele.removeAttribute(attr);
            ele.dataset.jssrc = oldAttr;
        }
    }
}

function loadSubelements(elements: HTMLCollectionOf<HTMLElement>, func: RequestCB) {
    // tslint:disable-next-line:prefer-for-of
    for (let i = 0; i < elements.length; i++) {
        const ele = elements[i];
        const srcStr = ele.dataset.jssrc;
        if (srcStr) {
            const src = mkUrl(srcStr);
            console.log("Found", ele, "with URL", src, "Adding to queue!");
            requestQueue.push({ ele, func, src });
        }
    }
}

function run() {
    console.log(`Running HTTP get of ${BASE_URL}`);
    httpGet({ url: BASE_URL, errorOnNon200: false }).then((res) => {
        BASE_URL = res.url!;

        const parser = new DOMParser();
        const doc = parser.parseFromString(arrayToString(res.body), "text/html") as HTMLDocument;

        rewriteSubelements(doc.getElementsByTagName("img"), "src");
        rewriteSubelements(doc.getElementsByTagName("script"), "src");

        const links = doc.getElementsByTagName("link");
        // tslint:disable-next-line:prefer-for-of
        for (let i = 0; i < links.length; i++) {
            const link = links[i] as HTMLLinkElement;
            if (link.rel !== "stylesheet") {
                continue;
            }
            const url = link.getAttribute("href");
            if (!url) {
                continue;
            }
            const parent = link.parentNode!;

            const newStyle = doc.createElement("style");
            newStyle.dataset.jssrc = url;

            parent.replaceChild(newStyle, link);
        }

        const docSrc = new XMLSerializer().serializeToString(doc);

        iframeDoc.open("text/html");
        iframeDoc.write(docSrc);
        iframeDoc.close();

        loadSubelements(iframeDoc.getElementsByTagName("img"), loadImgFunc);
        loadSubelements(iframeDoc.getElementsByTagName("style"), loadInnerTextFunc);
        loadSubelements(iframeDoc.getElementsByTagName("script"), loadInnerTextFunc);

        const aElements = iframeDoc.getElementsByTagName("a");
        // tslint:disable-next-line:prefer-for-of
        for (let i = 0; i < aElements.length; i++) {
            const aEle = aElements[i];
            const href = aEle.getAttribute("href");
            if (!href || href.startsWith("javascript:") || href.startsWith("#")) {
                continue;
            }
            if (aEle.target && aEle.target.startsWith("_")) {
                continue;
            }

            aEle.setAttribute("href", "javascript:void(0)");
            aEle.addEventListener("click", () => {
                BASE_URL = mkUrl(href);
                history.pushState({ loadedUrl: BASE_URL.href }, "");
                run();
            });
        }

        document.title = iframeDoc.title;

        setTimeout(requestQueueNext, 0);
    }).catch((err) => {
        console.error("Error fetching", err);
        setTimeout(requestQueueNext, 0);
    });
}

interface IMyHistoryState {
    loadedUrl?: string;
}

function checkHistoryUrl() {
    if (history.state) {
        const state = history.state as IMyHistoryState;
        if (state.loadedUrl) {
            BASE_URL = mkUrl(state.loadedUrl);
        }
    }
}

function main() {
    if (iframe) {
        return;
    }

    checkHistoryUrl();
    history.replaceState({ loadedUrl: BASE_URL.href }, "");

    iframe = document.getElementById("dataFrame")! as HTMLIFrameElement;
    iframeDoc = iframe.contentWindow!.document;

    const location = document.location!;

    const proto = (location.protocol === "http:") ? "ws:" : "wss:";
    let url = `${proto}//${location.host}/ws`;

    if (location.protocol === "file:" || location.hostname === "localhost") {
        url = "wss://doridian.net/ws";
    }

    const wsvpn = new WSVPN(url);
    addInterfaceEasy(wsvpn);
    return wsvpn.waitForInit().then(configOut).then(run);
}

window.addEventListener("popstate", () => {
    checkHistoryUrl();
    run();
});
window.addEventListener("DOMContentLoaded", main, false);
