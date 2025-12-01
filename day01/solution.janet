(defn slurp-lines [path]
  (string/split "\n" (string/trim (slurp path))))

(defn part-1 [lines]
  (var pos 50)
  (sum
    (seq [line :in lines]
      (def sign (if (string/has-prefix? "L" line) -1 1))
      (def num (scan-number (slice line 1)))
      (set pos (mod (+ pos (* sign num)) 100))
      (if (= pos 0) 1 0))))

(defn part-2 [lines]
  (var pos 50)
  (sum
    (seq [line :in lines]
      (def sign (if (string/has-prefix? "L" line) -1 1))
      (def num (scan-number (slice line 1)))
      (sum
        (seq [_ :range [0 num]]
          (set pos (mod (+ pos sign) 100))
          (if (= pos 0) 1 0))))))

(def lines (slurp-lines "input.txt"))
(pp (part-1 lines))
(pp (part-2 lines))
