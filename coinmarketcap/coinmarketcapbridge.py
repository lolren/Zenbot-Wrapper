#!/usr/bin/env python
# -*- coding: utf-8 -*-

import time
from coinmarketcap import Market

def timing(f):
    def wrap(*args):
        time1 = time.time()
        ret = f(*args)
        time2 = time.time()
        print '%s function took %0.3f ms' % (f.func_name, (time2-time1)*1000.0)
        return ret
    return wrap

@timing
def do_work():
    coinmarketcap = Market()
    print coinmarketcap.ticker(start=0, limit=3000)

if __name__ == '__main__':
    do_work()