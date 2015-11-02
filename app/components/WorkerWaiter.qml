/*
 * Copyright (C) 2014, 2015
 *      Andrew Hayzen <ahayzen@gmail.com>
 *      Daniel Holm <d.holmen@gmail.com>
 *      Victor Thompson <victor.thompson@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.4
import Ubuntu.Components 1.3


Timer {  // A timer to wait for a worker to stop
    id: waitForWorker
    interval: 16
    repeat: true

    property var func
    property var params  // don't use args/arguments as they are already defined/internal
    property WorkerScript worker

    onTriggered: {
        if (worker.processing === 0) {
            stop()
            func.apply(this, params)
        }
    }

    // Waits until the worker has stopped and then calls the func(*params)
    function workerStop(worker, func, params)
    {
        waitForWorker.func = func
        waitForWorker.params = params
        waitForWorker.worker = worker
        start()
    }
}
