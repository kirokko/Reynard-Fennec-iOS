// SPDX-License-Identifier: GPL-3.0-or-later
// Isolated worker: upstream explicitly supports running without vAPI.
import { dnrRulesetFromRawLists } from '../js/static-dnr-filtering.js';
import { AstFilterParser } from '../js/static-filtering-parser.js';
import { compileFilters } from './convert.mjs';
let queue = Promise.resolve();
self.onmessage = event => {
    const { id, text } = event.data;
    queue = queue.then(async () => {
        try {
            const result = await compileFilters(text, { dnrRulesetFromRawLists, AstFilterParser });
            self.postMessage({ id, result });
        } catch (error) { self.postMessage({ id, error: String(error.stack || error) }); }
    });
};
